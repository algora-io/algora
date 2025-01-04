defmodule Algora.Repo.Migrations.UpdateAccounts do
  use Ecto.Migration

  def up do
    alter table(:accounts) do
      modify :service_agreement, :string, null: true
      add :payouts_enabled, :boolean, null: false, default: false
      add :payout_interval, :string
      add :payout_speed, :integer
      add :default_currency, :string
    end

    drop index(:accounts, [:user_id])
    create unique_index(:accounts, [:user_id, :region])
  end

  def down do
    alter table(:accounts) do
      modify :service_agreement, :string, null: false
      drop :payouts_enabled
      drop :payout_interval
      drop :payout_speed
      drop :default_currency
    end

    create index(:accounts, [:user_id])
    drop unique_index(:accounts, [:user_id, :region])
  end
end
