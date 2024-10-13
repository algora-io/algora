defmodule Algora.Repo.Migrations.CreateMembers do
  use Ecto.Migration

  def change do
    create table(:members) do
      add :role, :string, null: false
      add :org_id, references(:users, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:members, [:org_id])
    create index(:members, [:user_id])
    create unique_index(:members, [:org_id, :user_id], name: :members_org_id_user_id_index)
  end
end
