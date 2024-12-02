defmodule Algora.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :provider, :string
      add :provider_id, :string
      add :provider_charge_id, :string
      add :provider_payment_intent_id, :string
      add :provider_transfer_id, :string
      add :provider_invoice_id, :string
      add :provider_balance_transaction_id, :string
      add :provider_meta, :map

      add :gross_amount, :money_with_currency
      add :net_amount, :money_with_currency
      add :total_fee, :money_with_currency
      add :provider_fee, :money_with_currency

      add :type, :string, null: false
      add :status, :string, null: false
      add :succeeded_at, :utc_datetime_usec
      add :reversed_at, :utc_datetime_usec

      # TODO: make this non-nullable
      add :user_id, references(:users)
      add :contract_id, references(:contracts)
      add :original_contract_id, references(:contracts)
      add :timesheet_id, references(:timesheets)
      add :bounty_id, references(:bounties)
      # add :claim_id, references(:claims)
      add :original_transaction_id, references(:transactions)

      timestamps()
    end

    # Add indexes for foreign keys and commonly queried fields
    create index(:transactions, [:user_id])
    create index(:transactions, [:contract_id])
    create index(:transactions, [:original_contract_id])
    create index(:transactions, [:timesheet_id])
    create index(:transactions, [:bounty_id])
    # create index(:transactions, [:claim_id])
    create index(:transactions, [:original_transaction_id])
    create index(:transactions, [:provider_id])
  end
end
