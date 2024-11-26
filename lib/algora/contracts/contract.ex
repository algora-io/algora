defmodule Algora.Contracts.Contract do
  use Algora.Model

  schema "contracts" do
    field :status, Ecto.Enum, values: [:draft, :active, :completed, :cancelled, :disputed]
    field :sequence_number, :integer, default: 1
    field :hourly_rate, :decimal
    field :hours_per_week, :integer
    field :start_date, :date
    field :end_date, :date
    field :total_paid, :decimal, default: Decimal.new(0)

    belongs_to :original_contract, Algora.Contracts.Contract
    has_many :renewals, Algora.Contracts.Contract, foreign_key: :original_contract_id

    belongs_to :client, Algora.Users.User
    belongs_to :provider, Algora.Users.User

    has_many :transactions, Algora.Payments.Transaction
    has_many :reviews, Algora.Reviews.Review

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
      :total_paid,
      :original_contract_id,
      :client_id,
      :provider_id
    ])
    |> validate_required([
      :status,
      :hourly_rate,
      :hours_per_week,
      :start_date,
      :client_id,
      :provider_id
    ])
    |> validate_number(:hours_per_week, greater_than: 0)
    |> validate_number(:hourly_rate, greater_than: 0)
    |> foreign_key_constraint(:client_id)
    |> foreign_key_constraint(:provider_id)
  end
end
