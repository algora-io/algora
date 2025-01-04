defmodule Algora.Repo.Migrations.UpdateAccounts do
  use Ecto.Migration

  def up do
    alter table(:accounts) do
      modify :service_agreement, :string, null: true
    end

    drop index(:accounts, [:user_id])
    create unique_index(:accounts, [:user_id, :region])
  end

  def down do
    alter table(:accounts) do
      modify :service_agreement, :string, null: false
    end

    create index(:accounts, [:user_id])
    drop unique_index(:accounts, [:user_id, :region])
  end
end
