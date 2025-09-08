defmodule Algora.Repo.Migrations.CreateReplies do
  use Ecto.Migration

  def change do
    create table(:replies, primary_key: false) do
      add :id, :string, primary_key: true
      add :from_email, :string, null: false
      add :from_name, :string
      add :to_email, :string, null: false
      add :subject, :string, null: false
      add :message_id, :string, null: false
      add :in_reply_to, :string
      add :references, :string
      add :original_body_text, :text
      add :original_body_html, :text
      add :reply_body_text, :text
      add :status, :string, default: "pending", null: false

      timestamps()
    end

    create index(:replies, [:status])
    create index(:replies, [:from_email])
    create index(:replies, [:inserted_at])
    create unique_index(:replies, [:message_id])
  end
end
