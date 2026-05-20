defmodule AlgoraWeb.EndpointSubdomainTest do
  use AlgoraWeb.ConnCase, async: true

  import Algora.Factory

  test "known profile subdomains redirect without creating a critical activity", %{conn: conn} do
    insert!(:user, handle: "acme")

    conn =
      conn
      |> Map.put(:host, "acme.algora.io")
      |> get("/jobs")

    assert redirected_to(conn, 301) == "http://localhost/acme/candidates/jobs"
    assert_activity_names([])
  end
end
