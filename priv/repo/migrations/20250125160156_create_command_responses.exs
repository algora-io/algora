defmodule Algora.Repo.Migrations.CreateCommandResponses do
  use Ecto.Migration

  def change do
    create table(:command_responses) do
      add :provider, :string, null: false
      add :provider_meta, :map, null: false
      add :provider_command_id, :string
      add :provider_response_id, :string, null: false
      add :command_source, :string, null: false
      add :command_type, :string, null: false
      add :ticket_id, references(:tickets), null: false

      timestamps()
    end

    create unique_index(:command_responses, [:provider, :provider_command_id, :command_source])
    create index(:command_responses, [:ticket_id])
  end
end
