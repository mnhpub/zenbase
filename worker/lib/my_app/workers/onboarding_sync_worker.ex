defmodule MyApp.Workers.OnboardingSyncWorker do
  use Oban.Worker, queue: :onboarding, max_attempts: 5, unique: [period: 60]

  alias Ecto.Adapters.SQL
  alias MyApp.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"tenant_id" => tenant_id, "onboarding_id" => onboarding_id, "params" => params}}) do
    # Call the RPC in Postgres
    sql = "SELECT public.rpc_onboarding_sync_tenant($1::uuid, $2::uuid, $3::jsonb) as result;"
    case SQL.query(Repo, sql, [tenant_id, onboarding_id, params]) do
      {:ok, %{rows: [[result_json]]}} ->
        # result_json is already a map if decoded by Postgrex with Jason
        {:ok, result_json}

      {:error, err} ->
        # Ensure we bubble up to trigger Oban retry handling
        {:error, err}
    end
  end
end
