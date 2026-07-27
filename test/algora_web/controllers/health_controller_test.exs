defmodule AlgoraWeb.HealthControllerTest do
  use AlgoraWeb.ConnCase

  setup do
    Algora.DeploymentHealth.up()

    on_exit(fn ->
      Algora.DeploymentHealth.up()
    end)
  end

  test "returns ok while the node is accepting traffic", %{conn: conn} do
    conn = get(conn, "/health")

    assert response(conn, 200) == "OK"
  end

  test "returns unavailable while the node is draining", %{conn: conn} do
    Algora.DeploymentHealth.down()

    conn = get(conn, "/health")

    assert response(conn, 503) == "Draining"
  end
end
