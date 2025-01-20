defmodule Algora.Payments.Transaction do
  @moduledoc false
  use Algora.Schema

  alias Algora.Contracts.Contract
  alias Algora.Types.Money

  @transaction_types [:charge, :transfer, :reversal, :debit, :credit, :deposit, :withdrawal]
  @transaction_statuses [:initialized, :processing, :succeeded, :failed, :canceled]

  @derive {Inspect, except: [:provider_meta]}
  typed_schema "transactions" do
    field :provider, :string
    field :provider_id, :string
    field :provider_charge_id, :string
    field :provider_payment_intent_id, :string
    field :provider_transfer_id, :string
    field :provider_invoice_id, :string
    field :provider_balance_transaction_id, :string
    field :provider_meta, :map

    field :gross_amount, Money
    field :net_amount, Money
    field :total_fee, Money
    field :provider_fee, Money
    field :line_items, {:array, :map}

    field :type, Ecto.Enum, values: @transaction_types
    field :status, Ecto.Enum, values: @transaction_statuses
    field :succeeded_at, :utc_datetime_usec
    field :reversed_at, :utc_datetime_usec
    field :group_id, :string

    belongs_to :timesheet, Algora.Contracts.Timesheet
    belongs_to :contract, Contract
    belongs_to :original_contract, Contract
    belongs_to :user, Algora.Accounts.User
    belongs_to :claim, Algora.Bounties.Claim
    belongs_to :bounty, Algora.Bounties.Bounty
    belongs_to :tip, Algora.Bounties.Tip
    belongs_to :linked_transaction, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :id,
      :provider,
      :provider_id,
      :provider_meta,
      :provider_invoice_id,
      :gross_amount,
      :net_amount,
      :total_fee,
      :type,
      :status,
      :timesheet_id,
      :contract_id,
      :original_contract_id,
      :user_id,
      :succeeded_at
    ])
    |> validate_required([
      :id,
      :provider,
      :provider_id,
      :provider_meta,
      :gross_amount,
      :net_amount,
      :total_fee,
      :type,
      :status,
      :contract_id,
      :original_contract_id,
      :user_id
    ])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:contract_id)
    |> foreign_key_constraint(:original_contract_id)
    |> foreign_key_constraint(:timesheet_id)
  end
end
