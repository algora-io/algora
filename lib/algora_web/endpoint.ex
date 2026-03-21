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

  # Subdomain aliases: subdomain → path prefix (overrides default routing)
  @subdomain_aliases %{
    "docs" => "/docs",
    "swift" => "/swift",
    "create" => "/anything",
    "lovablelabs" => "/lovable",
    "textqllabs" => "/textql",
    "comfy-org" => "/comfy"
  }

  # Subdomains that redirect to /challenges/:subdomain
  @challenge_subdomains ~w[clickhouse jules]

  # Subdomains that should not trigger any special routing
  @ignored_subdomains ~w[app console www sitemaps sitemap m api home ai test]

  # Legacy tRPC endpoint
  defp canonical_host(%{path_info: ["api", "trpc" | _]} = conn, _opts), do: conn

  defp canonical_host(%{path_info: ["health"]} = conn, _opts), do: conn

  defp canonical_host(%{host: host} = conn, _opts) do
    subdomain =
      host
      |> String.split(".")
      |> Enum.map(&String.downcase/1)
      |> case do
        [sub, "algora", "io"] -> sub
        [sub, "localhost"] -> sub
        _ -> nil
      end

    path = subdomain && path_for_subdomain(subdomain, conn)

    redirect_to_canonical_host(conn, path || conn.request_path)
  end

  defp path_for_subdomain(sub, _conn) when sub in @ignored_subdomains, do: nil

  defp path_for_subdomain(sub, conn) when is_map_key(@subdomain_aliases, sub) do
    Path.join([@subdomain_aliases[sub], conn.request_path])
  end

  defp path_for_subdomain(sub, _conn) when sub in @challenge_subdomains do
    "/challenges/#{sub}"
  end

  defp path_for_subdomain(sub, conn) do
    case Algora.Accounts.get_user_by_handle(sub) do
      nil ->
        conn.request_path

      _user ->
        Algora.Activities.alert("👀 Someone is viewing https://#{sub}.algora.io", :critical)
        "/#{sub}/candidates"
    end
  end

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
