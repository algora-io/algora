defmodule AlgoraWeb.Plugs.SaveRawPayload do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    {:ok, body, conn} = read_body(conn)
    conn |> put_private(:raw_payload, body)
  end
end
