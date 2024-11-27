defmodule Algora.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :text, null: false
      add :thread_id, references(:threads, on_delete: :delete_all), null: false
      add :sender_id, references(:users, on_delete: :nilify_all), null: false

      timestamps()
    end

    create index(:messages, [:thread_id])
    create index(:messages, [:sender_id])
  end
end
