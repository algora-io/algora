defmodule Algora.Repo.Migrations.CreateRepositories do
  use Ecto.Migration

  def change do
    create table(:repositories) do
      add :provider, :string, null: false
      add :provider_id, :string, null: false
      add :provider_meta, :map, null: false
      add :name, :string, null: false
      add :url, :string, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:repositories, [:user_id])

    # TODO: Reenable this after migration is complete.
    # create unique_index(:tasks, [:provider, :provider_id])
  end
end
