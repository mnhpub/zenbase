defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {Oban, oban_config()}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp oban_config do
    [
      repo: MyApp.Repo,
      queues: [onboarding: 10]
    ]
  end
end
