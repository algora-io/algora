defmodule AlgoraWeb.Plugs.RuntimeRewritePlug do
  @moduledoc """
  A plug that forwards requests to a runtime-configured upstream URL.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    upstream = Application.get_env(:algora, Keyword.get(opts, :upstream))

    if upstream do
      ReverseProxyPlug.call(conn, ReverseProxyPlug.init(upstream: upstream))
    else
      conn
      |> send_resp(500, "Upstream URL not configured")
      |> halt()
    end
  end
end
