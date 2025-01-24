defmodule Algora.Repo.Migrations.CreateActivities do
  use Ecto.Migration

  require Algora.Activities

  def change do
    Enum.each(Algora.Activities.tables(), fn table_name ->
      create table(table_name) do
        add :assoc_id, :string, null: false
        add :user_id, references(:users)
        add :type, :string, null: false
        add :visibility, :string, null: false
        add :template, :string
        add :meta, :map, null: false
        add :changes, :map, null: false
        add :trace_id, :string
        add :previous_event_id, references(table_name)
        add :notify_users, {:array, :string}, default: []

        timestamps()
      end

      create index(table_name, [:assoc_id])
      create index(table_name, [:user_id])
      create index(table_name, [:trace_id])
      create index(table_name, [:visibility])
    end)
  end
end
