import Config

config :my_app, ecto_repos: [MyApp.Repo]

config :my_app, MyApp.Repo,
  url: System.get_env("DATABASE_URL") || "postgres://postgres:password@localhost:5432/zenbase_test",
  pool_size: 10
