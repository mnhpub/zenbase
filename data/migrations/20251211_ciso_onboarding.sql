-- CISO Onboarding Migration

-- 1. Tenant Onboarding Table
CREATE TABLE IF NOT EXISTS public.onboardings (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  tenant_id uuid REFERENCES public.tenants(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending', -- pending | enqueued | processing | success | failed
  oban_job_id bigint, -- store Oban job id for linking
  params jsonb DEFAULT '{}'::jsonb,
  result jsonb,
  error text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_onboardings_tenant_id ON public.onboardings(tenant_id);

-- 2. Onboarding Audits Table
CREATE TABLE IF NOT EXISTS public.onboarding_audits (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  onboarding_id uuid REFERENCES public.onboardings(id) ON DELETE CASCADE,
  tenant_id uuid,
  action text NOT NULL,
  payload jsonb,
  before_state jsonb,
  after_state jsonb,
  rollback_payload jsonb,
  created_at timestamptz DEFAULT now()
);

-- 3. Domain Onboarding Table
CREATE TABLE IF NOT EXISTS public.domains (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  tenant_id uuid REFERENCES public.tenants(id) ON DELETE CASCADE,
  domain text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_domains_tenant_id ON public.domains(tenant_id);

-- 4. Tenant Onboarding RPC
-- Idempotent transactional onboarding sync
CREATE OR REPLACE FUNCTION public.rpc_onboarding_sync_tenant(
  p_tenant_id uuid,
  p_onboarding_id uuid,
  p_params jsonb DEFAULT '{}'::jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb := '{}'::jsonb;
  v_before jsonb;
  v_after jsonb;
BEGIN
  -- Basic validation
  PERFORM 1 FROM public.tenants WHERE id = p_tenant_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'tenant % not found', p_tenant_id;
  END IF;

  -- Capture before state for audit (example: existing domains)
  SELECT jsonb_agg(row_to_json(d)) INTO v_before
  FROM public.domains d WHERE d.tenant_id = p_tenant_id;

  -- Idempotent upsert of domain list passed in params { domains: ["a","b"] }
  IF p_params ? 'domains' THEN
    INSERT INTO public.domains (tenant_id, domain)
    SELECT p_tenant_id, trim(value)::text
    FROM jsonb_array_elements_text(p_params -> 'domains') AS t(value)
    ON CONFLICT (domain) DO UPDATE SET tenant_id = EXCLUDED.tenant_id
    WHERE public.domains.tenant_id IS DISTINCT FROM EXCLUDED.tenant_id;
  END IF;

  -- Example: update onboarding row status -> processing and store params/result
  UPDATE public.onboardings
  SET status = 'processing', params = p_params, updated_at = now()
  WHERE id = p_onboarding_id;

  -- After state for audit
  SELECT jsonb_agg(row_to_json(d)) INTO v_after
  FROM public.domains d WHERE d.tenant_id = p_tenant_id;

  -- Insert audit row
  INSERT INTO public.onboarding_audits (onboarding_id, tenant_id, action, payload, before_state, after_state)
  VALUES (p_onboarding_id, p_tenant_id, 'sync_domains', p_params, v_before, v_after);

  -- Prepare result
  v_result := jsonb_build_object('status', 'ok', 'domains_before', COALESCE(v_before, '[]'::jsonb), 'domains_after', COALESCE(v_after, '[]'::jsonb));

  -- Update onboarding final status and result
  UPDATE public.onboardings
  SET status = 'success', result = v_result, updated_at = now()
  WHERE id = p_onboarding_id;

  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  -- record failure on onboarding row and rethrow
  UPDATE public.onboardings
  SET status = 'failed', error = SQLERRM, updated_at = now()
  WHERE id = p_onboarding_id;

  -- insert audit failure row
  INSERT INTO public.onboarding_audits (onboarding_id, tenant_id, action, payload, before_state, after_state)
  VALUES (p_onboarding_id, p_tenant_id, 'sync_domains_failed', p_params, v_before, NULL);

  RAISE;
END;
$$;
