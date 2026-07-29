defmodule AlgoraWeb.Org.BountiesLiveTest do
  use AlgoraWeb.ConnCase, async: true

  import Algora.Factory
  import Phoenix.LiveViewTest

  alias AlgoraWeb.UserAuth

  setup %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, %{})
    org = insert!(:organization)
    repo = insert!(:repository, user: org, name: "algora")
    ticket = insert!(:ticket, repository: repo, number: 238, title: "Hide unauthorized bounty actions")
    bounty = insert!(:bounty, owner: org, creator: org, ticket: ticket, amount: Money.new!(2500, :USD))

    %{conn: conn, org: org, bounty: bounty}
  end

  test "hides bounty management actions from non-members", %{conn: conn, org: org} do
    user = insert!(:user)
    conn = UserAuth.put_current_user(conn, user)

    assert {:ok, _view, html} = live(conn, "/#{org.handle}/bounties")
    assert html =~ "Hide unauthorized bounty actions"
    refute html =~ "Edit Amount"
    refute html =~ "delete-bounty"
  end

  test "shows bounty management actions to org admins", %{conn: conn, org: org, bounty: bounty} do
    admin = insert!(:user)
    insert!(:member, user: admin, org: org, role: :admin)
    conn = UserAuth.put_current_user(conn, admin)

    assert {:ok, _view, html} = live(conn, "/#{org.handle}/bounties")
    assert html =~ "Edit Amount"
    assert html =~ ~s(phx-value-id="#{bounty.id}")
    assert html =~ "delete-bounty"
  end
end
