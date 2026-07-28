defmodule AlgoraWeb.SignInLiveTest do
  use AlgoraWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "explains GitHub authorization wording on login", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/auth/login")

    assert html =~ "GitHub calls this authorization"
    assert html =~ "act on your behalf"
    assert html =~ "Repository access is granted separately"
  end
end
