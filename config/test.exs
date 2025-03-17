import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :algora, Algora.Repo,
  url: System.get_env("TEST_DATABASE_URL"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  migration_primary_key: [type: :string],
  migration_timestamps: [type: :utc_datetime_usec]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :algora, AlgoraWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "M+VvXlmVxm5bl+xdXcImlpFP7Kob6M/sYK4SoaPgF0Spteix9NWw7WimjBQolY6V",
  server: false

config :algora, Oban, queues: false, plugins: false

# In test we don't send emails.
config :algora, Algora.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :algora, :github,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
  app_handle: System.get_env("GITHUB_APP_HANDLE"),
  app_id: System.get_env("GITHUB_APP_ID"),
  webhook_secret: System.get_env("GITHUB_WEBHOOK_SECRET"),
  private_key: System.get_env("GITHUB_PRIVATE_KEY"),
  pat: System.get_env("GITHUB_PAT"),
  pat_enabled: System.get_env("GITHUB_PAT_ENABLED", "false") == "true",
  oauth_state_ttl: String.to_integer(System.get_env("GITHUB_OAUTH_STATE_TTL", "600")),
  oauth_state_salt: System.get_env("GITHUB_OAUTH_STATE_SALT", "github-oauth-state")

config :algora, :stripe_client, Algora.Support.StripeMock
config :algora, :github_client, Algora.Support.GithubMock

config :algora,
  cloudflare_tunnel: System.get_env("CLOUDFLARE_TUNNEL"),
  swift_mode: false,
  auto_start_pollers: System.get_env("AUTO_START_POLLERS") == "true"

config :algora, :stripe,
  test_customer_id: System.get_env("STRIPE_TEST_CUSTOMER_ID"),
  test_account_id: System.get_env("STRIPE_TEST_ACCOUNT_ID")

config :algora, :login_code,
  ttl: String.to_integer(System.get_env("LOGIN_CODE_TTL", "3600")),
  salt: System.get_env("LOGIN_CODE_SALT", "algora-login-code")

config :algora, :plausible_url, System.get_env("PLAUSIBLE_URL")

config :algora, :assets_url, System.get_env("ASSETS_URL")
