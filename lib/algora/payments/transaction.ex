defmodule Algora.Payments.Transaction do
  use Algora.Model

  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:provider_meta]}
  schema "transactions" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :gross_amount, Money.Ecto.Composite.Type, no_fraction_if_integer: true
    field :net_amount, Money.Ecto.Composite.Type, no_fraction_if_integer: true
    field :total_fee, Money.Ecto.Composite.Type, no_fraction_if_integer: true
    field :provider_fee, Money.Ecto.Composite.Type, no_fraction_if_integer: true

    field :type, Ecto.Enum, values: [:charge, :transfer, :reversal]
    field :status, Ecto.Enum, values: [:initialized, :processing, :succeeded, :failed, :canceled]
    field :succeeded_at, :utc_datetime_usec
    field :reversed_at, :utc_datetime_usec

    belongs_to :timesheet, Algora.Contracts.Timesheet
    belongs_to :contract, Algora.Contracts.Contract
    belongs_to :original_contract, Algora.Contracts.Contract
    belongs_to :user, Algora.Users.User
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
      :type,
      :status,
      :timesheet_id,
      :contract_id,
      :user_id,
      :bounty_id,
      :original_transaction_id
    ])
    |> validate_required([
      :provider,
      :provider_id,
      :provider_meta,
      :amount,
      :type,
      :status
    ])
    |> foreign_key_constraint(:user_id)
  end
end
