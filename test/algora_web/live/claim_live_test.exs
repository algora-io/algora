defmodule AlgoraWeb.ClaimLiveTest do
  use AlgoraWeb.ConnCase, async: true

  import Algora.Factory
  import Phoenix.LiveViewTest

  describe "payment status" do
    test "shows approved claims as awaiting sponsor reward until the bounty is paid", %{conn: conn} do
      %{group_id: group_id} = create_claim_with_reward_status(:pending)

      assert {:ok, _view, html} = live(conn, ~p"/claims/#{group_id}")

      assert html =~ "Awaiting sponsor reward"
      assert html =~ "No contributor action is required"
    end

    test "shows rewarded after the sponsor payment succeeds", %{conn: conn} do
      %{group_id: group_id} = create_claim_with_reward_status(:paid)

      assert {:ok, _view, html} = live(conn, ~p"/claims/#{group_id}")

      assert html =~ "Rewarded"
      refute html =~ "Awaiting sponsor reward"
    end
  end

  defp create_claim_with_reward_status(status) do
    sponsor = insert!(:organization)
    contributor = insert!(:user)
    repository = insert!(:repository, user: sponsor)
    target = insert!(:ticket, repository: repository)
    bounty = insert!(:bounty, owner: sponsor, creator: sponsor, ticket: target, amount: Money.new!(100, :USD))
    claim = insert!(:claim, target: target, user: contributor, status: :approved)

    if status == :paid do
      insert!(
        :transaction,
        claim: claim,
        bounty: bounty,
        user: sponsor,
        type: :debit,
        status: :succeeded,
        net_amount: Money.new!(100, :USD)
      )
    end

    %{group_id: claim.group_id}
  end
end
