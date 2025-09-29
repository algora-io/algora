defmodule Algora.Repo.Migrations.CreateEmailsTable do
  use Ecto.Migration

  def change do
    create table(:emails, primary_key: false) do
      add :id, :string, primary_key: true

      # Essential email fields
      add :subject, :text, null: false
      add :sender, :string, null: false
      add :sender_email, :string, null: false
      add :to_recipients, :text
      add :cc_recipients, :text
      add :body, :text, null: false
      add :date, :utc_datetime, null: false
      add :gmail_id, :string, null: false
      add :message_id, :string, null: false
      add :thread_id, :string, null: false
      add :direction, :string, default: "incoming", null: false

      timestamps()
    end

    create unique_index(:emails, [:gmail_id])
    create index(:emails, [:thread_id])
    create index(:emails, [:date])
    create index(:emails, [:sender_email])
    create index(:emails, [:direction])
  end
end
