defmodule Algora.Repo.Migrations.CreateToolCallsTable do
  use Ecto.Migration

  def change do
    create table(:tool_calls, primary_key: false) do
      add :id, :string, primary_key: true
      add :agent_type, :string, null: false
      add :tool_name, :string, null: false
      add :arguments, :map, null: false
      add :context, :map
      add :result, :text
      add :user_id, references(:users, type: :string, on_delete: :delete_all)
      add :email_id, references(:emails, type: :string, on_delete: :delete_all)
      add :executed_at, :utc_datetime_usec, null: false
      add :success, :boolean, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:tool_calls, [:user_id])
    create index(:tool_calls, [:email_id])
    create index(:tool_calls, [:agent_type])
    create index(:tool_calls, [:tool_name])
    create index(:tool_calls, [:executed_at])
    create index(:tool_calls, [:success])
  end
end
