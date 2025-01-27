defmodule Algora.PaymentsTest do
  use Algora.DataCase

  import Mox

  alias Algora.Payments
  alias Algora.Payments.Account
  alias Algora.Payments.Transaction
  alias Algora.Repo

  setup :verify_on_exit!

  describe "perform/1" do
    setup do
      user = insert(:user)
      account = insert(:account, user: user)

      {:ok, user: user, account: account}
    end

    test "executes transfer when there are pending credits", %{user: user} do
      # Create a successful credit transaction
      insert(:transaction,
        user: user,
        type: :credit,
        status: :succeeded,
        net_amount: Money.new(1, :USD)
      )

      # Mock Stripe transfer creation
      expect(Algora.StripeMock, :create_transfer, fn params ->
        assert params.amount == 100
        assert params.currency == "USD"

        {:ok,
         %{
           id: "tr_123",
           status: :succeeded,
           amount: 100,
           currency: "USD"
         }}
      end)

      assert {:ok, _transfer} = Payments.execute_pending_transfers(user.id)

      # Verify transfer transaction was created
      transfer_tx = Repo.get_by(Transaction, provider_id: "tr_123")
      assert transfer_tx.status == :succeeded
      assert transfer_tx.type == :transfer
      assert Money.equal?(transfer_tx.net_amount, Money.new(1, :USD))
    end

    test "does nothing when user has no pending credits", %{user: user} do
      assert {:ok, nil} = Payments.execute_pending_transfers(user.id)

      assert Repo.aggregate(Transaction, :count) == 0
    end

    test "does nothing when user has no stripe account", %{user: user} do
      # Delete the account created in setup
      Repo.delete_all(Account)

      insert(:transaction,
        user: user,
        type: :credit,
        status: :succeeded,
        net_amount: Money.new(1000, :USD)
      )

      assert {:ok, nil} = Payments.execute_pending_transfers(user.id)

      # Verify no transfer was created
      transfer_count =
        Transaction
        |> where([t], t.type == :transfer)
        |> Repo.aggregate(:count)

      assert transfer_count == 0
    end

    test "handles failed stripe transfers", %{user: user} do
      insert(:transaction,
        user: user,
        type: :credit,
        status: :succeeded,
        net_amount: Money.new(1000, :USD)
      )

      expect(Algora.StripeMock, :create_transfer, fn _params ->
        {:error, %{message: "Insufficient funds"}}
      end)

      assert {:error, _} = Payments.execute_pending_transfers(user.id)

      # Verify transfer transaction status
      transfer_tx = Repo.one(from t in Transaction, where: t.type == :transfer)
      assert transfer_tx.status == :initialized
    end
  end
end
