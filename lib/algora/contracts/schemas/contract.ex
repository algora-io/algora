defmodule Algora.Contracts.Contract do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Activities.Activity
  alias Algora.Contracts.Contract
  alias Algora.MoneyUtils
  alias Algora.Validations

  typed_schema "contracts" do
    field :status, Ecto.Enum, values: [:draft, :active, :paid, :cancelled, :disputed]
    field :sequence_number, :integer, default: 1
    field :hourly_rate, Algora.Types.Money
    field :hourly_rate_min, Algora.Types.Money
    field :hourly_rate_max, Algora.Types.Money
    field :hours_per_week, :integer
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec

    field :amount_credited, Algora.Types.Money, virtual: true
    field :amount_debited, Algora.Types.Money, virtual: true

    field :total_charged, Algora.Types.Money, virtual: true
    field :total_credited, Algora.Types.Money, virtual: true
    field :total_debited, Algora.Types.Money, virtual: true
    field :total_deposited, Algora.Types.Money, virtual: true
    field :total_transferred, Algora.Types.Money, virtual: true
    field :total_withdrawn, Algora.Types.Money, virtual: true

    belongs_to :original_contract, Contract
    has_many :renewals, Contract, foreign_key: :original_contract_id

    belongs_to :client, User
    belongs_to :contractor, User

    has_many :transactions, Algora.Payments.Transaction
    has_many :reviews, Algora.Reviews.Review
    has_one :timesheet, Algora.Contracts.Timesheet

    has_many :activities, {"contract_activities", Activity}, foreign_key: :assoc_id

    timestamps()
  end

  def after_load({:ok, struct}), do: {:ok, after_load(struct)}
  def after_load({:error, _} = result), do: result
  def after_load(nil), do: nil

  def after_load(struct) do
    Enum.reduce(
      [
        :amount_credited,
        :amount_debited,
        :total_charged,
        :total_credited,
        :total_debited,
        :total_deposited,
        :total_transferred,
        :total_withdrawn
      ],
      struct,
      &MoneyUtils.ensure_money_field(&2, &1)
    )
  end

  def balance(contract) do
    :USD
    |> Money.zero()
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
    |> validate_required([:status, :hourly_rate, :hours_per_week, :client_id])
    |> validate_number(:hours_per_week, greater_than: 0)
    |> Validations.validate_money_positive(:hourly_rate)
    |> foreign_key_constraint(:client_id)
    |> foreign_key_constraint(:contractor_id)
    |> generate_id()
    |> put_original_contract_id()
  end

  def put_original_contract_id(changeset) do
    case get_field(changeset, :original_contract_id) do
      nil -> put_change(changeset, :original_contract_id, get_field(changeset, :id))
      _existing -> changeset
    end
  end
end
