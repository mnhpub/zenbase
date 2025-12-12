defmodule MyApp.Repo.Migrations.CisoOnboarding do
  use Ecto.Migration

  def up do
    execute """
    CREATE TABLE IF NOT EXISTS public.onboardings (
      id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
      tenant_id uuid REFERENCES public.tenants(id) ON DELETE CASCADE,
      status text NOT NULL DEFAULT 'pending',
      oban_job_id bigint,
      params jsonb DEFAULT '{}'::jsonb,
      result jsonb,
      error text,
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now()
    )
    """
    execute "CREATE INDEX IF NOT EXISTS idx_onboardings_tenant_id ON public.onboardings(tenant_id)"

    execute "ALTER TABLE public.onboardings ENABLE ROW LEVEL SECURITY"

    execute """
    CREATE POLICY "Tenants can view own onboarding"
      ON public.onboardings FOR SELECT
      USING (
        tenant_id IN (
          SELECT tenant_id FROM public.tenant_admins 
          WHERE user_id = auth.uid()
        )
      )
    """

    execute """
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
    )
    """

    execute """
    CREATE TABLE IF NOT EXISTS public.domains (
      id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
      tenant_id uuid REFERENCES public.tenants(id) ON DELETE CASCADE,
      domain text NOT NULL UNIQUE,
      created_at timestamptz DEFAULT now()
    )
    """
    execute "CREATE INDEX IF NOT EXISTS idx_domains_tenant_id ON public.domains(tenant_id)"

    execute """
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

      -- Capture before state
      SELECT jsonb_agg(row_to_json(d)) INTO v_before
      FROM public.domains d WHERE d.tenant_id = p_tenant_id;

      -- Idempotent upsert
      IF p_params ? 'domains' THEN
        INSERT INTO public.domains (tenant_id, domain)
        SELECT p_tenant_id, trim(value)::text
        FROM jsonb_array_elements_text(p_params -> 'domains') AS t(value)
        ON CONFLICT (domain) DO UPDATE SET tenant_id = EXCLUDED.tenant_id
        WHERE public.domains.tenant_id IS DISTINCT FROM EXCLUDED.tenant_id;
      END IF;

      -- Update processing status
      UPDATE public.onboardings
      SET status = 'processing', params = p_params, updated_at = now()
      WHERE id = p_onboarding_id;

      -- After state
      SELECT jsonb_agg(row_to_json(d)) INTO v_after
      FROM public.domains d WHERE d.tenant_id = p_tenant_id;

      -- Audit
      INSERT INTO public.onboarding_audits (onboarding_id, tenant_id, action, payload, before_state, after_state)
      VALUES (p_onboarding_id, p_tenant_id, 'sync_domains', p_params, v_before, v_after);

      -- Prepare result
      v_result := jsonb_build_object('status', 'ok', 'domains_before', COALESCE(v_before, '[]'::jsonb), 'domains_after', COALESCE(v_after, '[]'::jsonb));

      -- Final status
      UPDATE public.onboardings
      SET status = 'success', result = v_result, updated_at = now()
      WHERE id = p_onboarding_id;

      RETURN v_result;
    EXCEPTION WHEN OTHERS THEN
      UPDATE public.onboardings
      SET status = 'failed', error = SQLERRM, updated_at = now()
      WHERE id = p_onboarding_id;

      INSERT INTO public.onboarding_audits (onboarding_id, tenant_id, action, payload, before_state, after_state)
      VALUES (p_onboarding_id, p_tenant_id, 'sync_domains_failed', p_params, v_before, NULL);

      RAISE;
    END;
    $$
    """
  end

  def down do
    execute "DROP FUNCTION IF EXISTS public.rpc_onboarding_sync_tenant(uuid, uuid, jsonb)"
    execute "DROP TABLE IF EXISTS public.domains"
    execute "DROP TABLE IF EXISTS public.onboarding_audits"
    execute "DROP TABLE IF EXISTS public.onboardings"
  end
end
