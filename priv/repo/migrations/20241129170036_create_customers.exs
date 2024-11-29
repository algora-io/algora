defmodule Algora.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :provider, :string, null: false
      add :provider_id, :string, null: false
      add :provider_meta, :map, null: false
      add :name, :string, null: false
      add :region, :string, null: false
      add :user_id, references(:users, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:customers, [:user_id])
    create unique_index(:customers, [:provider, :provider_id])
  end
end
