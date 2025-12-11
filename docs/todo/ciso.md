# CISO

## Oban Design

- SQL (RPC + supporting tables), and an example Elixir Oban worker.
- Keep authoritative, idempotent DB changes inside a single RPC: public.rpc_onboarding_sync_tenant(tenant_id, onboarding_id, params jsonb).
- Oban worker calls the RPC and updates onboarding.status and stores job_id.
- Use least-privilege by granting EXECUTE on the RPC to the app role; avoid exposing direct table DML.

## Tables

### Tenant Onboarding
```sql
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
```

### Onboarding Audits
```sql
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
```

### Domain Onboarding
```sql
CREATE TABLE IF NOT EXISTS public.domains (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  tenant_id uuid REFERENCES public.tenants(id) ON DELETE CASCADE,
  domain text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_domains_tenant_id ON public.domains(tenant_id);
```

### Tenant Onboarding RPC
*Idempotent transactional onboarding sync.*

```sql
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
```

### RPC Notes
- The RPC is SECURITY DEFINER. After creating, revoke EXECUTE from public/anon and grant to your application DB role only.
- It is idempotent: domain upsert uses ON CONFLICT; re-running will not duplicate rows.
- The RPC updates onboarding.status — Oban worker will still record job_id and monitor result.

## Oban Worker

```elixir
defmodule MyApp.Workers.OnboardingSyncWorker do
  use Oban.Worker, queue: :onboarding, max_attempts: 5, unique: [period: 60]

  alias Ecto.Adapters.SQL
  alias MyApp.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"tenant_id" => tenant_id, "onboarding_id" => onboarding_id, "params" => params}}) do
    # Call the RPC in Postgres
    sql = "SELECT public.rpc_onboarding_sync_tenant($1::uuid, $2::uuid, $3::jsonb) as result;"
    case SQL.query(Repo, sql, [tenant_id, onboarding_id, Jason.encode!(params)]) do
      {:ok, %{rows: [[result_json]]}} ->
        # Optionally parse/update local state
        # Update onboardings with oban job id is done when enqueuing; ensure status handled
        {:ok, result_json}

      {:error, err} ->
        # Ensure we bubble up to trigger Oban retry handling
        {:error, err}
    end
  end
end
```

### Enqueue Example
```elixir
# 1. create onboarding row (returns id)
{:ok, onboarding} = %Onboarding{tenant_id: tenant.id, status: "enqueued", params: params}
|> Repo.insert()

# 2. enqueue Oban job and update onboarding.oban_job_id
{:ok, job} = MyApp.Workers.OnboardingSyncWorker.new(%{"tenant_id" => tenant.id, "onboarding_id" => onboarding.id, "params" => params})
|> Oban.insert()

Repo.update!(Ecto.Changeset.change(onboarding, oban_job_id: job.id, status: "enqueued"))
```

### Oban Notes
- Use Oban uniqueness: unique fields per tenant/onboarding to prevent duplicates (unique: [keys: ["onboarding_id"], period: 300]).
- Tune queue concurrency and DB pool size to avoid starving application connections.
- Set reasonable max_attempts and backoff strategy.

### Failure Handling
- On RPC error the function updates onboarding.status = 'failed' and records error text; Oban job will also record failure and can be retried.
- Surface onboarding.status and onboarding.error in UI; provide a "Retry" button that enqueues the same Oban worker again (or calls a retry RPC).
- For human remediation, show the last audit row (onboarding_audits) to help diagnose differences.

### Security and Least Privilege

*After creating RPC: revoke public execution, then grant EXECUTE to only the DB role used by your app/Oban workers.*

```sql
REVOKE EXECUTE ON FUNCTION public.rpc_onboarding_sync_tenant(uuid, uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rpc_onboarding_sync_tenant(uuid, uuid, jsonb) TO my_app_db_role;
```

> **Warning:** Do not grant direct INSERT/UPDATE privileges on domains/onboardings to the app role; keep RPC as the sanctioned path.

### Oban job uniqueness and retries
*(recommended worker options)*

- queue: :onboarding
- max_attempts: 5
- unique: [period: 300, keys: ["args->>'onboarding_id'"]]

This prevents duplicate jobs for same onboarding and limits retries.

## Observability

- Record Oban job id in onboardings and expose job status in your admin UI.
- Use Oban Web UI (oban_web) or telemetry to monitor failures, durations and retry counts.