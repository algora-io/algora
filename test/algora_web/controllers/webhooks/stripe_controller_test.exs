defmodule AlgoraWeb.Webhooks.StripeControllerTest do
  use AlgoraWeb.ConnCase
  use Oban.Testing, repo: Algora.Repo

  import Algora.Factory
  import Ecto.Query

  alias Algora.Payments
  alias Algora.Payments.PaymentMethod
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias AlgoraWeb.Webhooks.StripeController

  setup do
    # Insert a test customer
    user = insert(:user)
    customer = insert(:customer, user: user)

    # Common metadata for stripe events
    metadata = %{"version" => Payments.metadata_version()}

    {:ok, customer: customer, metadata: metadata}
  end

  describe "handle_event/1 for charge.succeeded" do
    test "updates transaction status and creates jobs for credits", %{metadata: metadata} do
      group_id = Ecto.UUID.generate()

      # Create test transactions in the group
      credit_tx =
        insert(:transaction, %{
          type: :credit,
          status: :pending,
          group_id: group_id
        })

      debit_tx =
        insert(:transaction, %{
          type: :debit,
          status: :pending,
          group_id: group_id
        })

      # Create stripe event
      event = %Stripe.Event{
        type: "charge.succeeded",
        data: %{
          object: %Stripe.Charge{
            metadata: Map.put(metadata, "group_id", group_id)
          }
        }
      }

      assert {:ok, nil} = StripeController.handle_event(event)

      # Assert transactions were updated
      assert Repo.get(Transaction, credit_tx.id).status == :succeeded
      assert Repo.get(Transaction, debit_tx.id).status == :succeeded

      # Assert jobs were created
      assert_enqueued(worker: Payments.Jobs.ExecutePendingTransfer, args: %{credit_id: credit_tx.id})
    end
  end

  describe "handle_event/1 for transfer.created" do
    test "updates associated transaction status", %{metadata: metadata} do
      transfer_id = "tr_#{Ecto.UUID.generate()}"

      transaction =
        insert(:transaction, %{
          provider: "stripe",
          provider_id: transfer_id,
          status: :pending
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

      assert {:ok, nil} = StripeController.handle_event(event)

      updated_tx = Repo.get(Transaction, transaction.id)
      assert updated_tx.status == :succeeded
      assert updated_tx.succeeded_at != nil
    end
  end

  describe "handle_event/1 for checkout.session.completed" do
    test "creates payment method for setup mode", %{customer: customer} do
      setup_intent_id = "seti_#{Ecto.UUID.generate()}"
      payment_method_id = "pm_#{Ecto.UUID.generate()}"

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

      # Assert payment method was created
      payment_method = Repo.one!(from p in PaymentMethod, where: p.provider_id == ^payment_method_id)
      assert payment_method.customer_id == customer.id
    end
  end
end
