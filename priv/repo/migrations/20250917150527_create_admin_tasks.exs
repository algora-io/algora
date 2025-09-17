defmodule Algora.Repo.Migrations.CreateAdminTasks do
  use Ecto.Migration

  def change do
    create table(:admin_tasks, primary_key: false) do
      add :id, :string, primary_key: true
      add :type, :string, null: false
      add :completed_at, :utc_datetime_usec
      add :discarded_at, :utc_datetime_usec
      add :payload, :map, null: false
      add :origin_id, :string
      add :seq, :integer
      add :logs, {:array, :map}, default: []
      add :pinned, :boolean, default: false

      timestamps()
    end

    create index(:admin_tasks, [:type])
    create index(:admin_tasks, [:origin_id])
    create index(:admin_tasks, [:seq])
    create index(:admin_tasks, [:completed_at])
    create index(:admin_tasks, [:discarded_at])
    create index(:admin_tasks, [:pinned])
    create index(:admin_tasks, [:inserted_at])
  end
end
