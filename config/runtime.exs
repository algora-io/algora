import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/algora start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :algora, AlgoraWeb.Endpoint, server: true
end

if config_env() == :prod do
  config :algora, :github,
    client_id: System.fetch_env!("GITHUB_CLIENT_ID"),
    client_secret: System.fetch_env!("GITHUB_CLIENT_SECRET"),
    app_handle: System.fetch_env!("GITHUB_APP_HANDLE"),
    app_id: System.fetch_env!("GITHUB_APP_ID"),
    webhook_secret: System.fetch_env!("GITHUB_WEBHOOK_SECRET"),
    private_key: System.fetch_env!("GITHUB_PRIVATE_KEY"),
    pat: System.fetch_env!("GITHUB_PAT"),
    pat_enabled: System.get_env("GITHUB_PAT_ENABLED", "true") == "true",
    oauth_state_ttl: String.to_integer(System.get_env("GITHUB_OAUTH_STATE_TTL", "600")),
    oauth_state_salt: System.fetch_env!("GITHUB_OAUTH_STATE_SALT")

  config :stripity_stripe,
    api_key: System.fetch_env!("STRIPE_SECRET_KEY")

  config :algora, :stripe,
    secret_key: System.fetch_env!("STRIPE_SECRET_KEY"),
    publishable_key: System.fetch_env!("STRIPE_PUBLISHABLE_KEY"),
    webhook_secret: System.fetch_env!("STRIPE_WEBHOOK_SECRET")

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :algora, Algora.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    migration_primary_key: [type: :string],
    migration_timestamps: [type: :utc_datetime_usec]

  config :ex_aws,
    json_codec: Jason,
    access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")

  config :ex_aws, :s3,
    scheme: "https://",
    host: URI.parse(System.fetch_env!("AWS_ENDPOINT_URL_S3")).host,
    region: System.fetch_env!("AWS_REGION")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :algora, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :algora, AlgoraWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :algora, AlgoraWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :algora, AlgoraWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  config :algora, Algora.Mailer,
    adapter: Swoosh.Adapters.Sendgrid,
    api_key: System.fetch_env!("SENDGRID_API_KEY")

  config :swoosh, :api_client, Swoosh.ApiClient.Finch

  config :algora,
    bucket_name: System.fetch_env!("BUCKET_NAME"),
    auto_start_pollers: System.get_env("AUTO_START_POLLERS") == "true"

  config :algora, :discord, webhook_url: System.get_env("DISCORD_WEBHOOK_URL")

  config :algora, :login_code,
    ttl: String.to_integer(System.get_env("LOGIN_CODE_TTL", "3600")),
    salt: System.fetch_env!("LOGIN_CODE_SALT")
end
