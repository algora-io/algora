defmodule Algora.Repo.Migrations.CreateInstallations do
  use Ecto.Migration

  def change do
    create table(:installations) do
      add :provider, :string, null: false
      add :provider_id, :string, null: false
      add :provider_login, :string, null: false
      add :provider_meta, :map, null: false
      add :avatar_url, :string
      add :repository_selection, :string
      add :owner_id, references(:users, on_delete: :nilify_all)
      add :connected_user_id, references(:users, on_delete: :nilify_all)
      timestamps()
    end

    create index(:installations, [:owner_id])
    create index(:installations, [:connected_user_id])
    create unique_index(:installations, [:provider, :provider_id])
  end
end
