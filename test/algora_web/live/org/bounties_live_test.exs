defmodule AlgoraWeb.Org.BountiesLiveTest do
  use AlgoraWeb.ConnCase, async: true

  import Algora.Factory
  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    repo_owner = insert!(:organization)
    org = insert!(:organization)
    user = insert!(:user)

    repository = insert!(:repository, user: repo_owner)
    ticket = insert!(:ticket, repository: repository)
    insert!(:bounty, owner: org, creator: org, ticket: ticket)

    %{conn: Phoenix.ConnTest.init_test_session(conn, %{}), org: org, user: user}
  end

  test "hides bounty management actions from logged-out viewers", %{conn: conn, org: org} do
    {:ok, _view, html} = live(conn, ~p"/#{org.handle}/bounties")

    refute html =~ "Edit Amount"
    refute html =~ "Delete"
  end

  test "hides bounty management actions from non-member viewers", %{conn: conn, org: org, user: user} do
    conn = AlgoraWeb.UserAuth.put_current_user(conn, user)

    {:ok, _view, html} = live(conn, ~p"/#{org.handle}/bounties")

    refute html =~ "Edit Amount"
    refute html =~ "Delete"
  end

  test "shows bounty management actions to org moderators", %{conn: conn, org: org, user: user} do
    insert!(:member, org: org, user: user, role: :mod)
    conn = AlgoraWeb.UserAuth.put_current_user(conn, user)

    {:ok, _view, html} = live(conn, ~p"/#{org.handle}/bounties")

    assert html =~ "Edit Amount"
    assert html =~ "Delete"
  end
end
