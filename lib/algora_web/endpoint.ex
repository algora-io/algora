defmodule AlgoraWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :algora

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  alias AlgoraWeb.Plugs.CanonicalHostPlug

  @session_options [
    store: :cookie,
    key: "_algora_key",
    signing_salt: "muCIIw3j",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [:x_headers, session: @session_options]],
    longpoll: [connect_info: [:x_headers, session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :algora,
    gzip: false,
    only: AlgoraWeb.static_paths()

  if Code.ensure_loaded?(Tidewave) do
    plug Tidewave
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :algora
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Stripe.WebhookPlug,
    at: "/webhooks/stripe",
    handler: AlgoraWeb.Webhooks.StripeController,
    secret: {Algora, :config, [[:stripe, :webhook_secret]]}

  plug AlgoraWeb.Plugs.GithubWebhooks,
    at: "/webhooks/github",
    handler: AlgoraWeb.Webhooks.GithubController

  plug(:canonical_host)

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug AlgoraWeb.Router

  # Legacy tRPC endpoint
  defp canonical_host(%{path_info: ["api", "trpc" | _]} = conn, _opts), do: conn

  defp canonical_host(%{path_info: ["health"]} = conn, _opts), do: conn

  defp canonical_host(%{host: "docs.algora.io"} = conn, _opts),
    do: redirect_to_canonical_host(conn, Path.join(["/docs", conn.request_path]))

  defp canonical_host(%{host: "clickhouse.algora.io"} = conn, _opts) do
    redirect_to_canonical_host(conn, "/challenges/clickhouse")
  end

  defp canonical_host(%{host: "swift.algora.io"} = conn, _opts) do
    redirect_to_canonical_host(conn, "/swift")
  end

  defp canonical_host(%{host: host} = conn, _opts) do
    case String.split(host, ".") do
      [subdomain, "algora", "io"]
      when subdomain not in ["app", "console", "www", "sitemaps", "sitemap", "m", "api", "home", "ai"] ->
        case Algora.Accounts.get_user_by_handle(subdomain) do
          nil ->
            redirect_to_canonical_host(conn, conn.request_path)

          _user ->
            Algora.Activities.alert("👀 Someone is viewing https://#{subdomain}.algora.io", :critical)
            redirect_to_canonical_host(conn, Path.join(["/#{subdomain}/candidates"]))
        end

      _ ->
        redirect_to_canonical_host(conn, conn.request_path)
    end
  end

  defp canonical_host(conn, _opts), do: redirect_to_canonical_host(conn, conn.request_path)

  defp redirect_to_canonical_host(conn, path) do
    :algora
    |> Application.get_env(:canonical_host)
    |> case do
      host when is_binary(host) ->
        opts = CanonicalHostPlug.init(canonical_host: host, path: path)
        CanonicalHostPlug.call(conn, opts)

      _ ->
        conn
    end
  end
end
