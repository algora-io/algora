defmodule AlgoraWeb.HealthController do
  use AlgoraWeb, :controller

  def index(conn, _params) do
    send_resp(conn, 200, "OK")
  end
end
