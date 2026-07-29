defmodule AlgoraWeb.Org.BountiesLiveTest do
  use AlgoraWeb.ConnCase, async: true

  import Algora.Factory
  import Phoenix.LiveViewTest

  alias AlgoraWeb.UserAuth

  describe "open bounty actions" do
    test "hides edit and delete actions from non-managers", %{conn: conn} do
      org = insert!(:organization)
      user = insert!(:user)
      repo = insert!(:repository, user: org)
      ticket = insert!(:ticket, repository: repo)
      insert!(:bounty, owner: org, ticket: ticket)
      insert!(:member, user: user, org: org, role: :expert)

      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> UserAuth.put_current_user(user)

      {:ok, _view, html} = live(conn, ~p"/#{org.handle}/bounties")

      refute html =~ "edit-bounty-amount"
      refute html =~ "delete-bounty"
    end

    test "shows edit and delete actions to managers", %{conn: conn} do
      org = insert!(:organization)
      user = insert!(:user)
      repo = insert!(:repository, user: org)
      ticket = insert!(:ticket, repository: repo)
      insert!(:bounty, owner: org, ticket: ticket)
      insert!(:member, user: user, org: org, role: :mod)

      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> UserAuth.put_current_user(user)

      {:ok, _view, html} = live(conn, ~p"/#{org.handle}/bounties")

      assert html =~ "edit-bounty-amount"
      assert html =~ "delete-bounty"
    end
  end
end
