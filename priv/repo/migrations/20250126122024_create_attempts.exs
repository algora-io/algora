defmodule Algora.Repo.Migrations.CreateAttempts do
  use Ecto.Migration

  def change do
    create table(:attempts) do
      add :status, :string, null: false, default: "active"
      add :warnings_count, :integer, null: false, default: 0

      add :ticket_id, references(:tickets, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:attempts, [:ticket_id])
    create index(:attempts, [:user_id])

    create unique_index(:attempts, [:ticket_id, :user_id])
  end
end
