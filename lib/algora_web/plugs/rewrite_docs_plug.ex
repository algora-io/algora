defmodule AlgoraWeb.Plugs.RewriteDocsPlug do
  @moduledoc false
  def init(options), do: options

  def call(%Plug.Conn{} = conn, _ \\ []) do
    conn
    |> Plug.Conn.register_before_send(&transform_body/1)
    |> Plug.Conn.update_req_header("accept-encoding", "identity", fn _ -> "identity" end)
  end

  def transform_body(%Plug.Conn{} = conn) do
    proxy_url = "https://docs.algora.io"

    body =
      if conn.resp_body do
        conn.resp_body
        |> String.replace("src=\"/", "src=\"#{proxy_url}/")
        |> String.replace("href=\"/", "href=\"#{proxy_url}/")
        |> String.replace("#{proxy_url}", AlgoraWeb.Endpoint.url())
      end

    %Plug.Conn{conn | resp_body: body}
  end
end
