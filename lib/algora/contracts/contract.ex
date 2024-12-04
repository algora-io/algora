defmodule Algora.Contracts.Contract do
  use Algora.Model

  schema "contracts" do
    field :status, Ecto.Enum, values: [:draft, :active, :paid, :cancelled, :disputed]
    field :sequence_number, :integer, default: 1
    field :hourly_rate, Money.Ecto.Composite.Type, no_fraction_if_integer: true
    field :hours_per_week, :integer
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec

    belongs_to :original_contract, Algora.Contracts.Contract
    has_many :renewals, Algora.Contracts.Contract, foreign_key: :original_contract_id

    has_many :chain,
      through: [:original_contract, :renewals],
      where: [original_contract_id: nil]

    belongs_to :client, Algora.Users.User
    belongs_to :contractor, Algora.Users.User

    has_many :transactions, Algora.Payments.Transaction
    has_many :reviews, Algora.Reviews.Review
    has_one :timesheet, Algora.Contracts.Timesheet

    has_one :latest_charge, Algora.Payments.Transaction,
      where: [status: :succeeded, type: :charge],
      preload_order: [desc: :succeeded_at]

    has_one :latest_transfer, Algora.Payments.Transaction,
      where: [status: :succeeded, type: :transfer],
      preload_order: [desc: :succeeded_at]

    timestamps()
  end

  def changeset(contract, attrs) do
    contract
    |> cast(attrs, [
      :status,
      :sequence_number,
      :hourly_rate,
      :hours_per_week,
      :start_date,
      :end_date,
      :original_contract_id,
      :client_id,
      :contractor_id
    ])
    |> validate_required([
      :status,
      :hourly_rate,
      :hours_per_week,
      :start_date,
      :client_id,
      :contractor_id
    ])
    |> validate_number(:hours_per_week, greater_than: 0)
    |> validate_number(:hourly_rate, greater_than: 0)
    |> foreign_key_constraint(:client_id)
    |> foreign_key_constraint(:contractor_id)
    |> generate_id()
  end
end
