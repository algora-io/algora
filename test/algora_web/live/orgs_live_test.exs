defmodule AlgoraWeb.OrgsLiveTest do
  use AlgoraWeb.ConnCase

  import Algora.Factory
  import Phoenix.LiveViewTest

  test "renders project technology tags", %{conn: conn} do
    org =
      insert(:organization,
        display_name: "Kyo",
        handle: "kyo",
        tech_stack: ["Scala", "TypeScript"],
        featured: true
      )

    insert!(:transaction,
      user: org,
      net_amount: Money.new(1000, :USD),
      type: :debit,
      status: :succeeded
    )

    {:ok, _view, html} = live(conn, ~p"/projects")

    assert html =~ "Kyo"
    assert html =~ "Scala"
    assert html =~ "TypeScript"
  end
end
