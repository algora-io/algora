defmodule Algora.Repo.Migrations.UpdateAccountsAndCustomers do
  use Ecto.Migration

  def up do
    alter table(:accounts) do
      modify :service_agreement, :string, null: true
      add :payouts_enabled, :boolean, null: false, default: false
      add :payout_interval, :string
      add :payout_speed, :integer
      add :default_currency, :string
      remove :region
    end

    alter table(:customers) do
      remove :region
    end

    drop index(:accounts, [:user_id])
    create unique_index(:accounts, [:user_id])
  end

  def down do
    alter table(:accounts) do
      modify :service_agreement, :string, null: false
      remove :payouts_enabled
      remove :payout_interval
      remove :payout_speed
      remove :default_currency
      add :region, :string, null: false
    end

    alter table(:customers) do
      add :region, :string, null: false
    end

    create index(:accounts, [:user_id])
    drop unique_index(:accounts, [:user_id])
  end
end
