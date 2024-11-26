defmodule Algora.Contracts do
  import Ecto.Query
  alias Algora.Repo
  alias Algora.Contracts.Contract
  alias Algora.Payments.Transaction

  def get_contract!(id), do: Repo.get!(Contract, id)

  def create_contract(attrs) do
    %Contract{}
    |> Contract.changeset(attrs)
    |> Repo.insert()
  end

  def renew_contract(contract, attrs \\ %{}) do
    next_sequence = get_next_sequence_number(contract)

    %Contract{}
    |> Contract.changeset(
      Map.merge(attrs, %{
        original_contract_id: contract.original_contract_id || contract.id,
        sequence_number: next_sequence,
        status: :active,
        client_id: contract.client_id,
        provider_id: contract.provider_id,
        start_date: Date.utc_today(),
        total_paid: Decimal.new(0)
      })
    )
    |> Repo.insert()
  end

  def process_payment(contract, %{stripe_charge_id: charge_id} = attrs) do
    Repo.transaction(fn ->
      # Create charge transaction
      charge_attrs = %{
        provider: "stripe",
        provider_id: charge_id,
        provider_meta: attrs.stripe_metadata,
        amount: calculate_total_amount(contract, attrs.fee_percentage),
        currency: "USD",
        type: :charge,
        status: :completed,
        sender_id: contract.client_id,
        contract_id: contract.id,
        hours_worked: contract.hours_per_week,
        fee_percentage: attrs.fee_percentage
      }

      {:ok, charge} = Repo.insert(Transaction.changeset(%Transaction{}, charge_attrs))

      # Create transfer transaction
      transfer_attrs = %{
        provider: "stripe",
        provider_id: attrs.stripe_transfer_id,
        provider_meta: attrs.stripe_metadata,
        amount: contract.hourly_rate |> Decimal.mult(Decimal.new(contract.hours_per_week)),
        currency: "USD",
        type: :transfer,
        status: :completed,
        sender_id: contract.client_id,
        recipient_id: contract.provider_id,
        contract_id: contract.id,
        hours_worked: contract.hours_per_week,
        fee_percentage: attrs.fee_percentage
      }

      {:ok, transfer} = Repo.insert(Transaction.changeset(%Transaction{}, transfer_attrs))

      # Update contract total_paid
      {:ok, updated_contract} = update_contract_total_paid(contract, transfer.amount)

      {updated_contract, charge, transfer}
    end)
  end

  # Private helpers

  defp get_next_sequence_number(contract) do
    query =
      from c in Contract,
        where: c.original_contract_id == ^(contract.original_contract_id || contract.id),
        select: max(c.sequence_number)

    case Repo.one(query) do
      # First renewal
      nil -> 2
      max -> max + 1
    end
  end

  defp calculate_total_amount(contract, fee_percentage) do
    base_amount = Decimal.mult(contract.hourly_rate, Decimal.new(contract.hours_per_week))
    fee = Decimal.mult(base_amount, Decimal.div(Decimal.new(fee_percentage), Decimal.new(100)))
    Decimal.add(base_amount, fee)
  end

  defp update_contract_total_paid(contract, amount) do
    contract
    |> Contract.changeset(%{total_paid: Decimal.add(contract.total_paid, amount)})
    |> Repo.update()
  end
end
