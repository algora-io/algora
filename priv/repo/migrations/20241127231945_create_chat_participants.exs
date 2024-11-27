defmodule Algora.Repo.Migrations.CreateChatParticipants do
  use Ecto.Migration

  def change do
    create table(:chat_participants) do
      add :last_read_at, :utc_datetime, null: false
      add :thread_id, references(:threads, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:chat_participants, [:thread_id])
    create index(:chat_participants, [:user_id])
    create unique_index(:chat_participants, [:thread_id, :user_id])
  end
end
