defmodule AlgoraWeb.HealthController do
  use AlgoraWeb, :controller

  def index(conn, _params) do
    if Algora.DeploymentHealth.healthy?() do
      send_resp(conn, 200, "OK")
    else
      send_resp(conn, 503, "Draining")
    end
  end
end
