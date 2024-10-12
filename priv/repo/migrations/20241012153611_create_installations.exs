defmodule Algora.Repo.Migrations.CreateInstallations do
  use Ecto.Migration

  def change do
    create table(:installations) do
      add :provider, :string, null: false
      add :provider_id, :string, null: false
      add :provider_login, :string, null: false
      add :provider_meta, :map, null: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:installations, [:user_id])
    create unique_index(:installations, [:provider, :provider_id])
  end
end
