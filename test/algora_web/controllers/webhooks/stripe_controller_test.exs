defmodule AlgoraWeb.Webhooks.StripeControllerTest do
  use AlgoraWeb.ConnCase
  use Oban.Testing, repo: Algora.Repo

  import Algora.Factory
  import Ecto.Query

  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Tip
  alias Algora.Contracts.Contract
  alias Algora.Payments
  alias Algora.Payments.PaymentMethod
  alias Algora.Payments.Transaction
  alias Algora.PSP
  alias Algora.Repo
  alias AlgoraWeb.Webhooks.StripeController

  setup do
    sender = insert(:user)
    recipient = insert(:user)
    customer = insert(:customer, user: sender)
    metadata = %{"version" => Payments.metadata_version()}
    {:ok, customer: customer, metadata: metadata, sender: sender, recipient: recipient}
  end

  describe "handle_event/1 for charge.succeeded" do
    test "updates transaction statuses and marks associated records as paid", %{
      metadata: metadata,
      sender: sender,
      recipient: recipient
    } do
      group_id = "#{Algora.Util.random_int()}"

      bounty = insert(:bounty, status: :open, owner_id: sender.id, ticket: insert(:ticket))
      tip = insert(:tip, status: :open, owner_id: sender.id, recipient: recipient)
      contract = insert(:contract, status: :active, client: sender, contractor: recipient)

      bounty_credit_tx =
        insert(:transaction, %{
          type: :credit,
          status: :initialized,
          group_id: group_id,
          user_id: recipient.id,
          bounty_id: bounty.id
        })

      tip_credit_tx =
        insert(:transaction, %{
          type: :credit,
          status: :initialized,
          group_id: group_id,
          user_id: recipient.id,
          tip_id: tip.id
        })

      contract_credit_tx =
        insert(:transaction, %{
          type: :credit,
          status: :initialized,
          group_id: group_id,
          user_id: recipient.id,
          contract_id: contract.id
        })

      event = %Stripe.Event{
        type: "charge.succeeded",
        data: %{
          object: %Stripe.Charge{
            metadata: Map.put(metadata, "group_id", group_id)
          }
        }
      }

      assert :ok = StripeController.handle_event(event)

      assert Repo.get(Transaction, bounty_credit_tx.id).status == :succeeded
      assert Repo.get(Transaction, tip_credit_tx.id).status == :succeeded
      assert Repo.get(Transaction, contract_credit_tx.id).status == :succeeded

      assert Repo.get(Bounty, bounty.id).status == :paid
      assert Repo.get(Tip, tip.id).status == :paid
      assert Repo.get(Contract, contract.id).status == :paid
    end

    test "updates transaction status and enqueues PromptPayoutConnect job", %{
      metadata: metadata,
      sender: sender,
      recipient: recipient
    } do
      group_id = "#{Algora.Util.random_int()}"

      debit_tx =
        insert(:transaction, %{
          type: :debit,
          status: :initialized,
          group_id: group_id,
          user_id: sender.id
        })

      credit_tx =
        insert(:transaction, %{
          type: :credit,
          status: :initialized,
          group_id: group_id,
          user_id: recipient.id
        })

      event = %Stripe.Event{
        type: "charge.succeeded",
        data: %{
          object: %Stripe.Charge{
            metadata: Map.put(metadata, "group_id", group_id)
          }
        }
      }

      assert :ok = StripeController.handle_event(event)

      assert Repo.get(Transaction, credit_tx.id).status == :succeeded
      assert Repo.get(Transaction, debit_tx.id).status == :succeeded

      assert_enqueued(worker: Bounties.Jobs.PromptPayoutConnect)
    end

    test "updates transaction status and enqueues ExecutePendingTransfer for enabled accounts", %{
      metadata: metadata,
      sender: sender,
      recipient: recipient
    } do
      _account = insert(:account, %{user_id: recipient.id, payouts_enabled: true})
      group_id = "#{Algora.Util.random_int()}"

      debit_tx =
        insert(:transaction, %{
          type: :debit,
          status: :initialized,
          group_id: group_id,
          user_id: sender.id
        })

      credit_tx =
        insert(:transaction, %{
          type: :credit,
          status: :initialized,
          group_id: group_id,
          user_id: recipient.id
        })

      event = %Stripe.Event{
        type: "charge.succeeded",
        data: %{
          object: %Stripe.Charge{
            metadata: Map.put(metadata, "group_id", group_id)
          }
        }
      }

      assert :ok = StripeController.handle_event(event)

      assert Repo.get(Transaction, credit_tx.id).status == :succeeded
      assert Repo.get(Transaction, debit_tx.id).status == :succeeded

      assert_enqueued(worker: Payments.Jobs.ExecutePendingTransfer, args: %{credit_id: credit_tx.id})
    end
  end

  describe "handle_event/1 for transfer.created" do
    test "updates associated transaction status", %{metadata: metadata} do
      transfer_id = "tr_#{Algora.Util.random_int()}"

      transaction =
        insert(:transaction, %{
          provider: "stripe",
          provider_id: transfer_id,
          type: :transfer,
          status: :initialized
        })

      event = %Stripe.Event{
        type: "transfer.created",
        data: %{
          object: %Stripe.Transfer{
            id: transfer_id,
            metadata: metadata
          }
        }
      }

      assert :ok = StripeController.handle_event(event)

      updated_tx = Repo.get(Transaction, transaction.id)
      assert updated_tx.status == :succeeded
      assert updated_tx.succeeded_at != nil

      assert_enqueued(worker: Bounties.Jobs.NotifyTransfer, args: %{transfer_id: transaction.id})
    end
  end

  describe "handle_event/1 for checkout.session.completed" do
    test "creates payment method for setup mode", %{customer: customer} do
      setup_intent_id = "seti_#{Algora.Util.random_int()}"

      event = %Stripe.Event{
        type: "checkout.session.completed",
        data: %{
          object: %Stripe.Session{
            customer: customer.provider_id,
            mode: "setup",
            setup_intent: setup_intent_id
          }
        }
      }

      assert :ok = StripeController.handle_event(event)

      {:ok, setup_intent} = PSP.SetupIntent.retrieve(setup_intent_id, %{})

      payment_method = Repo.one!(from p in PaymentMethod, where: p.provider_id == ^setup_intent.payment_method)
      assert payment_method.customer_id == customer.id
    end
  end
end
