defmodule AlgoraWeb.StoreSessionController do
  use AlgoraWeb, :controller

  def create(conn, params) do
    dbg(params)

    updated_conn =
      Enum.reduce(params, conn, fn {key, value}, acc_conn ->
        put_session(acc_conn, String.to_existing_atom(key), value)
      end)

    send_resp(updated_conn, 200, "")
  end
end
