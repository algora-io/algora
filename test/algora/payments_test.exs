defmodule Algora.PaymentsTest do
  use Algora.DataCase
  use Oban.Testing, repo: Algora.Repo

  import ExUnit.CaptureLog

  alias Algora.Payments
  alias Algora.Payments.Account
  alias Algora.Payments.Jobs.ExecutePendingTransfer
  alias Algora.Payments.Transaction
  alias Algora.Repo

  setup do
    user = insert(:user)
    account = insert(:account, user: user)

    {:ok, user: user, account: account}
  end

  describe "execute_pending_transfer/1" do
    test "executes transfer when user has positive balance", %{user: user, account: account} do
      credit =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(1, :USD)
        )

      assert {:ok, transfer} = Payments.execute_pending_transfer(credit.id)
      assert transfer.amount == 100
      assert transfer.currency == "usd"
      assert transfer.destination == account.provider_id

      transfer_tx = Repo.get_by(Transaction, provider_id: transfer.id)
      assert transfer_tx.status == :succeeded
      assert transfer_tx.type == :transfer
      assert transfer_tx.provider == "stripe"
      assert transfer_tx.provider_meta["id"] == transfer.id
      assert Money.equal?(transfer_tx.net_amount, Money.new(1, :USD))
      assert Money.equal?(transfer_tx.gross_amount, Money.new(1, :USD))
      assert Money.equal?(transfer_tx.total_fee, Money.new(0, :USD))

      assert Transaction |> where([t], t.type == :transfer) |> Repo.aggregate(:count) == 1
    end

    test "does nothing when user has positive unconfirmed balance", %{user: user} do
      credit =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :processing,
          net_amount: Money.new(1, :USD)
        )

      assert {:error, :not_found} = Payments.execute_pending_transfer(credit.id)
      assert Transaction |> where([t], t.type == :transfer) |> Repo.aggregate(:count) == 0
    end

    test "does nothing when user has payouts disabled", %{user: user, account: account} do
      account |> change(payouts_enabled: false) |> Repo.update()

      credit =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(1, :USD)
        )

      {result, _log} = with_log(fn -> Payments.execute_pending_transfer(credit.id) end)
      assert {:error, :no_active_account} = result
      assert Transaction |> where([t], t.type == :transfer) |> Repo.aggregate(:count) == 0
    end

    test "does nothing when user has no stripe account", %{user: user} do
      Repo.delete_all(Account)

      credit =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(1, :USD)
        )

      {result, _log} = with_log(fn -> Payments.execute_pending_transfer(credit.id) end)
      assert {:error, :no_active_account} = result
      assert Transaction |> where([t], t.type == :transfer) |> Repo.aggregate(:count) == 0
    end

    test "handles failed stripe transfers", %{user: user} do
      credit =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(1, :USD)
        )

      Account |> Repo.one!() |> change(%{provider_id: "acct_invalid"}) |> Repo.update!()

      {result, _log} = with_log(fn -> Payments.execute_pending_transfer(credit.id) end)
      assert {:error, %Stripe.Error{code: :invalid_request_error}} = result

      transfer_tx = Repo.one(from t in Transaction, where: t.type == :transfer)
      assert transfer_tx.status == :failed
    end

    test "prevents duplicate transfers", %{user: user} do
      credit_tx =
        insert(:transaction,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(1, :USD),
          group_id: Nanoid.generate(),
          user: user
        )

      {:ok, transfer} = Payments.execute_pending_transfer(credit_tx.id)
      {:ok, transfer_tx} = Repo.fetch_by(Transaction, type: :transfer, provider_id: transfer.id)

      assert Money.equal?(transfer_tx.net_amount, Money.new(1, :USD))
      assert transfer_tx.status == :succeeded
      assert transfer_tx.succeeded_at
      assert transfer_tx.group_id == credit_tx.group_id
      assert transfer_tx.user_id == credit_tx.user_id
      assert transfer_tx.provider_id == transfer.id

      {:ok, transfer2} = Payments.execute_pending_transfer(credit_tx.id)
      {:ok, transfer_tx2} = Repo.fetch_by(Transaction, type: :transfer, provider_id: transfer2.id)

      assert transfer2.id == transfer.id
      assert transfer_tx2.id == transfer_tx.id
    end

    test "allows retrying failed/canceled transfers", %{user: user, account: account} do
      credit_tx =
        insert(:transaction,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(1, :USD),
          group_id: Nanoid.generate(),
          user: user
        )

      Account |> Repo.one!() |> change(%{provider_id: "acct_invalid"}) |> Repo.update!()
      {result, _log} = with_log(fn -> Payments.execute_pending_transfer(credit_tx.id) end)
      assert {:error, %Stripe.Error{code: :invalid_request_error}} = result

      Account |> Repo.one!() |> change(%{provider_id: account.provider_id}) |> Repo.update!()
      {:ok, transfer} = Payments.execute_pending_transfer(credit_tx.id)
      {:ok, transfer_tx} = Repo.fetch_by(Transaction, type: :transfer, status: :succeeded)

      assert Money.equal?(transfer_tx.net_amount, Money.new(1, :USD))
      assert transfer_tx.status == :succeeded
      assert transfer_tx.succeeded_at
      assert transfer_tx.group_id == credit_tx.group_id
      assert transfer_tx.user_id == credit_tx.user_id
      assert transfer_tx.provider_id == transfer.id
    end
  end

  describe "enqueue_pending_transfers/1" do
    setup do
      user = insert(:user)
      account = insert(:account, user: user)

      {:ok, user: user, account: account}
    end

    test "enqueues transfer when user has positive balance", %{user: user} do
      credit1 =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(1, :USD)
        )

      credit2 =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(2, :USD)
        )

      assert {:ok, nil} = Payments.enqueue_pending_transfers(user.id)
      assert_enqueued(worker: ExecutePendingTransfer, args: %{credit_id: credit1.id})
      assert_enqueued(worker: ExecutePendingTransfer, args: %{credit_id: credit2.id})
    end

    test "does nothing when user has positive unconfirmed balance", %{user: user} do
      credit =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :processing,
          net_amount: Money.new(1, :USD)
        )

      assert {:ok, nil} = Payments.enqueue_pending_transfers(user.id)
      refute_enqueued(worker: ExecutePendingTransfer)
      refute_enqueued(worker: ExecutePendingTransfer, args: %{credit_id: credit.id})
    end

    test "does nothing when user has zero balance", %{user: user} do
      assert {:ok, nil} = Payments.enqueue_pending_transfers(user.id)
      refute_enqueued(worker: ExecutePendingTransfer)
    end

    test "does nothing when user has payouts disabled", %{user: user, account: account} do
      account |> change(payouts_enabled: false) |> Repo.update()

      credit =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(1, :USD)
        )

      {result, _log} = with_log(fn -> Payments.enqueue_pending_transfers(user.id) end)
      assert {:error, :no_active_account} = result
      refute_enqueued(worker: ExecutePendingTransfer)
      refute_enqueued(worker: ExecutePendingTransfer, args: %{credit_id: credit.id})
    end

    test "does nothing when user has no stripe account", %{user: user} do
      Repo.delete_all(Account)

      credit =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(1, :USD)
        )

      {result, _log} = with_log(fn -> Payments.enqueue_pending_transfers(user.id) end)
      assert {:error, :no_active_account} = result
      refute_enqueued(worker: ExecutePendingTransfer)
      refute_enqueued(worker: ExecutePendingTransfer, args: %{credit_id: credit.id})
    end
  end

  describe "execute_transfer/2" do
    test "executes transfer idempotently with same transfer ID and transaction ID", %{account: account} do
      credit_tx =
        insert(:transaction,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(1, :USD),
          group_id: Nanoid.generate()
        )

      {:ok, transfer_tx} = Payments.fetch_or_create_transfer(credit_tx)
      {:ok, transfer1} = Payments.execute_transfer(transfer_tx, account)
      {:ok, transfer_tx1} = Repo.fetch_by(Transaction, type: :transfer)

      assert Money.equal?(transfer_tx1.net_amount, Money.new(1, :USD))
      assert transfer_tx1.status == :succeeded
      assert transfer_tx1.succeeded_at
      assert transfer_tx1.group_id == credit_tx.group_id
      assert transfer_tx1.user_id == credit_tx.user_id
      assert transfer_tx1.provider_id == transfer1.id

      {:ok, transfer_tx} = Payments.fetch_or_create_transfer(credit_tx)
      {:ok, transfer2} = Payments.execute_transfer(transfer_tx, account)
      {:ok, transfer_tx2} = Repo.fetch_by(Transaction, type: :transfer)

      assert Money.equal?(transfer_tx2.net_amount, Money.new(1, :USD))
      assert transfer_tx2.status == :succeeded
      assert transfer_tx2.succeeded_at
      assert transfer_tx2.group_id == credit_tx.group_id
      assert transfer_tx2.user_id == credit_tx.user_id
      assert transfer_tx2.provider_id == transfer2.id

      assert transfer1.id == transfer2.id
      assert transfer_tx1.id == transfer_tx2.id
    end
  end

  describe "refresh_stripe_account/1" do
    test "executes pending transfers", %{user: user} do
      group_id0 = Nanoid.generate()
      group_id1 = Nanoid.generate()
      group_id2 = Nanoid.generate()

      credit0 =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(100, :USD),
          group_id: group_id0
        )

      _transfer0 =
        insert(:transaction,
          user: user,
          type: :transfer,
          status: :succeeded,
          net_amount: Money.new(100, :USD),
          group_id: group_id0
        )

      credit1 =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(100, :USD),
          group_id: group_id1
        )

      credit2 =
        insert(:transaction,
          user: user,
          type: :credit,
          status: :succeeded,
          net_amount: Money.new(100, :USD),
          group_id: group_id2
        )

      assert {:ok, _account} = Payments.refresh_stripe_account(user)
      jobs = all_enqueued()
      assert length(jobs) == 2
      refute_enqueued(worker: ExecutePendingTransfer, args: %{credit_id: credit0.id})
      assert_enqueued(worker: ExecutePendingTransfer, args: %{credit_id: credit1.id})
      assert_enqueued(worker: ExecutePendingTransfer, args: %{credit_id: credit2.id})

      assert {:ok, _account} = Payments.refresh_stripe_account(user)
      jobs = all_enqueued()
      assert length(jobs) == 2
    end
  end
end
