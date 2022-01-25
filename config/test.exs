use Mix.Config

config :paper_trail, ecto_repos: [PaperTrail.Repo, PaperTrail.UUIDRepo]

config :paper_trail, repo: PaperTrail.Repo, originator: [name: :user, model: User]

config :paper_trail, PaperTrail.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  database: "paper_trail_test",
  hostname: System.get_env("PG_HOST") || "localhost",
  poolsize: 10,
  show_sensitive_data_on_connection_error: true

config :paper_trail, PaperTrail.UUIDRepo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  database: "paper_trail_uuid_test",
  hostname: System.get_env("PG_HOST") || "localhost",
  poolsize: 10,
  show_sensitive_data_on_connection_error: true

config :logger, level: :warn
