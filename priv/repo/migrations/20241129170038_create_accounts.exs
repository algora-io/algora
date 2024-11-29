defmodule Algora.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :provider, :string, null: false
      add :provider_id, :string, null: false
      add :provider_meta, :map, null: false

      add :name, :string
      add :details_submitted, :boolean, null: false, default: false
      add :charges_enabled, :boolean, null: false, default: false
      add :service_agreement, :string, null: false
      add :country, :string, null: false
      add :type, :string, null: false
      add :region, :string, null: false
      add :stale, :boolean, null: false, default: false

      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:accounts, [:user_id])
    create unique_index(:accounts, [:provider, :provider_id])
  end
end
