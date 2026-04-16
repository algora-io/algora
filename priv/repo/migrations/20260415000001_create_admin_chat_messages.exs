defmodule Algora.Repo.Migrations.CreateAdminChatMessages do
  use Ecto.Migration

  def change do
    create table(:admin_chat_messages, primary_key: false) do
      add :id, :string, primary_key: true
      add :role, :string, null: false
      add :content, :text, null: false
      add :visible, :boolean, null: false, default: true

      add :job_match_id, references(:job_matches, type: :string, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:admin_chat_messages, [:job_match_id])
    create index(:admin_chat_messages, [:job_match_id, :inserted_at])
  end
end
