defmodule AlgoraWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :algora

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_algora_key",
    signing_salt: "muCIIw3j",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :algora,
    gzip: false,
    only: AlgoraWeb.static_paths()

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

  plug :parse_body

  opts = [
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  ]

  defmodule BodyReader do
    def cache_raw_body(conn, opts) do
      with {:ok, body, conn} <- Plug.Conn.read_body(conn, opts) do
        conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])

        {:ok, body, conn}
      end
    end
  end

  @parser_without_cache Plug.Parsers.init(opts)
  @parser_with_cache Plug.Parsers.init([body_reader: {BodyReader, :cache_raw_body, []}] ++ opts)

  # All endpoints that start with "webhooks" have their body cached.
  defp parse_body(%{path_info: ["webhooks" | _]} = conn, _),
    do: Plug.Parsers.call(conn, @parser_with_cache)

  defp parse_body(conn, _),
    do: Plug.Parsers.call(conn, @parser_without_cache)

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug AlgoraWeb.Router
end
