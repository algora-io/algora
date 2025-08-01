# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :algora,
  title: "Algora",
  description: "Algora connects companies and engineers for full-time and contract work",
  ecto_repos: [Algora.Repo],
  generators: [timestamp_type: :utc_datetime_usec],
  redirects: [
    {"/tv", "https://tv.algora.io"},
    {"/discord", "https://discord.gg/9RXD2nqbnG"},
    {"/docs/bounties/payments", "/docs/payments"},
    {"/sdk", "https://github.com/algora-io/sdk"},
    {"/healthcare", "https://blog.algora.io/post/healthcare"},
    {"/podcast", "https://www.youtube.com/@algora-io/podcasts"},
    {"/create/org", "/onboarding/org"},
    {"/solve", "/onboarding/dev"},
    {"/onboarding/solver", "/onboarding/dev"},
    {"/:org/contract/:id", "/:org/contracts/:id"},
    {"/org/*path", "/*path"},
    {"/@/:handle", "/:handle/profile"},
    {"/challenges/limbo", "/challenges/turso"}
  ]

# Configures the endpoint
config :algora, AlgoraWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: AlgoraWeb.ErrorHTML, json: AlgoraWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Algora.PubSub,
  live_view: [signing_salt: "lTPawhId"]

config :algora, Oban,
  notifier: Oban.Notifiers.PG,
  repo: Algora.ObanRepo,
  get_dynamic_repo: {Algora.Repo, :oban_repo, []},
  queues: [
    # --- #
    event_consumers: 1,
    comment_consumers: 1,
    search_consumers: 1,
    delivery_consumers: 1,
    notify_bounty: 1,
    notify_tip_intent: 1,
    notify_claim: 1,
    transfers: 1,
    activity_notifier: 1,
    activity_mailer: 1,
    campaign_emails: 1,
    fetch_top_contributions: 1,
    job_invitations: 1,
    # --- #
    github_og_image: 1,
    notify_transfer: 1,
    prompt_payout_connect: 1,
    activity_discord: 1,
    sync_contribution: 5
  ]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :algora, Algora.Mailer, adapter: Swoosh.Adapters.Local

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  algora: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "[$level] $message $metadata\n",
  level: String.to_atom(System.get_env("LOG_LEVEL") || "debug"),
  metadata: [:mfa, :file, :line, :request_id, :user_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :nanoid,
  size: 16,
  alphabet: "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

config :ex_money,
  default_cldr_backend: Algora.Cldr

config :ex_cldr,
  default_locale: "en",
  default_backend: Algora.Cldr

config :tails,
  color_classes: [
    "primary",
    "primary-foreground",
    "secondary",
    "secondary-foreground",
    "destructive",
    "destructive-foreground",
    "destructive-50",
    "destructive-100",
    "destructive-200",
    "destructive-300",
    "destructive-400",
    "destructive-500",
    "destructive-600",
    "destructive-700",
    "destructive-800",
    "destructive-900",
    "destructive-950",
    "success",
    "success-foreground",
    "success-50",
    "success-100",
    "success-200",
    "success-300",
    "success-400",
    "success-500",
    "success-600",
    "success-700",
    "success-800",
    "success-900",
    "success-950",
    "warning",
    "warning-foreground",
    "warning-50",
    "warning-100",
    "warning-200",
    "warning-300",
    "warning-400",
    "warning-500",
    "warning-600",
    "warning-700",
    "warning-800",
    "warning-900",
    "warning-950",
    "muted",
    "muted-foreground",
    "accent",
    "accent-foreground",
    "popover",
    "popover-foreground",
    "card",
    "card-foreground",
    "border",
    "input",
    "ring",
    "background",
    "foreground",
    "gray"
  ]

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :reverse_proxy_plug, :http_client, ReverseProxyPlug.HTTPClient.Adapters.HTTPoison

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
