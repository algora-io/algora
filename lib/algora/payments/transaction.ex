defmodule Algora.Payments.Transaction do
  use Algora.Model

  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:provider_meta]}
  schema "transactions" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map
    field :amount, :decimal
    field :currency, :string
    field :type, Ecto.Enum, values: [:charge, :transfer, :refund]
    field :status, Ecto.Enum, values: [:pending, :processing, :succeeded, :failed, :canceled]
    field :succeeded_at, :utc_datetime
    field :refunded_at, :utc_datetime

    belongs_to :timesheet, Algora.Contracts.Timesheet
    belongs_to :contract, Algora.Contracts.Contract
    belongs_to :sender, Algora.Users.User
    belongs_to :recipient, Algora.Users.User
    # belongs_to :claim, Algora.Bounties.Claim
    belongs_to :bounty, Algora.Bounties.Bounty
    belongs_to :original_transaction, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :provider,
      :provider_id,
      :provider_meta,
      :amount,
      :currency,
      :type,
      :status,
      :timesheet_id,
      :contract_id,
      :sender_id,
      :recipient_id,
      :bounty_id,
      :original_transaction_id
    ])
    |> validate_required([
      :provider,
      :provider_id,
      :provider_meta,
      :amount,
      :currency,
      :type,
      :status
    ])
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:sender_id)
    |> foreign_key_constraint(:recipient_id)
  end
end
