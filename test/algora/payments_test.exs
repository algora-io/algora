defmodule Algora.PaymentsTest do
  use Algora.DataCase

  import Mox

  alias Algora.Payments
  alias Algora.Payments.Account
  alias Algora.Payments.Transaction
  alias Algora.Repo

  setup :verify_on_exit!

  describe "execute_pending_transfers/1" do
    setup do
      user = insert(:user)
      account = insert(:account, user: user)

      {:ok, user: user, account: account}
    end

    test "executes transfer when there are pending credits", %{user: user, account: account} do
      insert(:transaction,
        user: user,
        type: :credit,
        status: :succeeded,
        net_amount: Money.new(1, :USD)
      )

      insert(:transaction,
        user: user,
        type: :credit,
        status: :succeeded,
        net_amount: Money.new(2, :USD)
      )

      stripe_transfer_id = "tr_#{Nanoid.generate()}"

      expect(Algora.StripeMock, :create_transfer, fn params ->
        {:ok,
         %{
           id: stripe_transfer_id,
           amount: params.amount,
           currency: params.currency,
           destination: params.destination
         }}
      end)

      assert {:ok, transfer} = Payments.execute_pending_transfers(user.id)
      assert transfer.id == stripe_transfer_id
      assert transfer.amount == 100 + 200
      assert transfer.currency == "usd"
      assert transfer.destination == account.provider_id

      transfer_tx = Repo.get_by(Transaction, provider_id: stripe_transfer_id)
      assert transfer_tx.status == :succeeded
      assert transfer_tx.type == :transfer
      assert transfer_tx.provider == "stripe"
      assert transfer_tx.provider_meta["id"] == stripe_transfer_id
      assert Money.equal?(transfer_tx.net_amount, Money.new(1 + 2, :USD))
      assert Money.equal?(transfer_tx.gross_amount, Money.new(1 + 2, :USD))
      assert Money.equal?(transfer_tx.total_fee, Money.new(0, :USD))
    end

    test "does nothing when user has no pending credits", %{user: user} do
      assert {:ok, nil} = Payments.execute_pending_transfers(user.id)

      assert Repo.aggregate(Transaction, :count) == 0
    end

    test "does nothing when user has payouts disabled", %{user: user, account: account} do
      account |> change(payouts_enabled: false) |> Repo.update()

      insert(:transaction,
        user: user,
        type: :credit,
        status: :succeeded,
        net_amount: Money.new(1, :USD)
      )

      assert {:ok, nil} = Payments.execute_pending_transfers(user.id)
      assert Transaction |> where([t], t.type == :transfer) |> Repo.aggregate(:count) == 0
    end

    test "does nothing when user has no stripe account", %{user: user} do
      Repo.delete_all(Account)

      insert(:transaction,
        user: user,
        type: :credit,
        status: :succeeded,
        net_amount: Money.new(1, :USD)
      )

      assert {:ok, nil} = Payments.execute_pending_transfers(user.id)
      assert Transaction |> where([t], t.type == :transfer) |> Repo.aggregate(:count) == 0
    end

    test "handles failed stripe transfers", %{user: user} do
      insert(:transaction,
        user: user,
        type: :credit,
        status: :succeeded,
        net_amount: Money.new(1, :USD)
      )

      expect(Algora.StripeMock, :create_transfer, fn _params ->
        {:error, %{message: "Insufficient funds"}}
      end)

      assert {:error, _} = Payments.execute_pending_transfers(user.id)

      transfer_tx = Repo.one(from t in Transaction, where: t.type == :transfer)
      assert transfer_tx.status == :failed
    end
  end
end
