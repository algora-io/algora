defmodule Algora.Contracts.Contract do
  use Algora.Schema
  alias Money.Ecto.Composite.Type, as: MoneyType
  alias Algora.MoneyUtils

  schema "contracts" do
    field :status, Ecto.Enum, values: [:draft, :active, :paid, :cancelled, :disputed]
    field :sequence_number, :integer, default: 1
    field :hourly_rate, MoneyType, no_fraction_if_integer: true
    field :hourly_rate_min, MoneyType, no_fraction_if_integer: true
    field :hourly_rate_max, MoneyType, no_fraction_if_integer: true
    field :hours_per_week, :integer
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec

    field :amount_credited, MoneyType, virtual: true, no_fraction_if_integer: true
    field :amount_debited, MoneyType, virtual: true, no_fraction_if_integer: true

    field :total_charged, MoneyType, virtual: true, no_fraction_if_integer: true
    field :total_credited, MoneyType, virtual: true, no_fraction_if_integer: true
    field :total_debited, MoneyType, virtual: true, no_fraction_if_integer: true
    field :total_deposited, MoneyType, virtual: true, no_fraction_if_integer: true
    field :total_transferred, MoneyType, virtual: true, no_fraction_if_integer: true
    field :total_withdrawn, MoneyType, virtual: true, no_fraction_if_integer: true

    belongs_to :original_contract, Algora.Contracts.Contract
    has_many :renewals, Algora.Contracts.Contract, foreign_key: :original_contract_id

    belongs_to :client, Algora.Users.User
    belongs_to :contractor, Algora.Users.User

    has_many :transactions, Algora.Payments.Transaction
    has_many :reviews, Algora.Reviews.Review
    has_one :timesheet, Algora.Contracts.Timesheet

    timestamps()
  end

  def after_load({:ok, struct}), do: {:ok, after_load(struct)}
  def after_load({:error, _} = result), do: result
  def after_load(nil), do: nil

  def after_load(struct) do
    [
      :amount_credited,
      :amount_debited,
      :total_charged,
      :total_credited,
      :total_debited,
      :total_deposited,
      :total_transferred,
      :total_withdrawn
    ]
    |> Enum.reduce(struct, &MoneyUtils.ensure_money_field(&2, &1))
  end

  def balance(contract) do
    Money.zero(:USD)
    |> Money.add!(contract.total_charged)
    |> Money.add!(contract.total_deposited)
    |> Money.sub!(contract.total_debited)
    |> Money.sub!(contract.total_withdrawn)
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

  def draft_changeset(contract, attrs) do
    contract
    |> cast(attrs, [
      :status,
      :sequence_number,
      :hourly_rate_min,
      :hourly_rate_max,
      :hours_per_week,
      :start_date,
      :end_date,
      :original_contract_id,
      :client_id,
    ])
    |> validate_required([
      :status,
      :hourly_rate_min,
      :hourly_rate_max,
      :hours_per_week,
      :start_date,
      :client_id,
    ])
    |> validate_number(:hours_per_week, greater_than: 0)
    |> foreign_key_constraint(:client_id)
    |> generate_id()
  end
end
