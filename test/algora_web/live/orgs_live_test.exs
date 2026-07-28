defmodule AlgoraWeb.OrgsLiveTest do
  use AlgoraWeb.ConnCase, async: false

  import Algora.Factory
  import Phoenix.LiveViewTest

  test "renders project technology tags", %{conn: conn} do
    user = insert(:user)

    org =
      insert(:organization,
        display_name: "Golem Cloud",
        handle: "golem-cloud",
        featured: true,
        tech_stack: ["Rust", "TypeScript"],
        bio: "Build and deploy durable workers"
      )

    insert(:transaction, user: org, net_amount: Money.new(1000, :USD), type: :debit, status: :succeeded)

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> AlgoraWeb.UserAuth.put_current_user(user)

    {:ok, _view, html} = live(conn, ~p"/projects")

    assert html =~ "Golem Cloud"
    assert html =~ "Rust"
    assert html =~ "TypeScript"
  end
end
