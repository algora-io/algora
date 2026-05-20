defmodule AlgoraWeb.UserControllerTest do
  use AlgoraWeb.ConnCase

  import Algora.Factory

  test "redirects legacy profile paths for individuals", %{conn: conn} do
    user = insert(:user)

    conn = get(conn, "/profile/#{user.handle}")

    assert redirected_to(conn) == "/#{user.handle}/profile"
  end

  test "redirects legacy profile paths for organizations", %{conn: conn} do
    org = insert(:organization)

    conn = get(conn, "/profile/#{org.handle}")

    assert redirected_to(conn) == "/#{org.handle}/dashboard"
  end

  test "raises not found for unknown legacy profile handles", %{conn: conn} do
    assert_raise AlgoraWeb.NotFoundError, fn ->
      get(conn, "/profile/missing-profile-handle")
    end
  end
end
