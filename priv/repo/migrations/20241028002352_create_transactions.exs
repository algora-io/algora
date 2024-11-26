defmodule Algora.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :provider, :string
      add :provider_id, :string
      add :provider_meta, :map
      add :succeeded_at, :utc_datetime
      add :amount, :decimal, null: false
      add :currency, :string, null: false
      add :type, :string

      # add :account_id, references(:accounts)
      # add :customer_id, references(:customers)
      add :recipient_id, references(:users)
      add :bounty_id, references(:bounties)
      # add :claim_id, references(:claims)
      # add :project_id, references(:projects)

      timestamps()
    end

    # Add indexes for foreign keys and commonly queried fields
    # create index(:transactions, [:account_id])
    # create index(:transactions, [:customer_id])
    create index(:transactions, [:recipient_id])
    create index(:transactions, [:bounty_id])
    # create index(:transactions, [:claim_id])
    # create index(:transactions, [:project_id])
    create index(:transactions, [:provider_id])
  end
end
