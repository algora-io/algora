defmodule Algora.Repo.Migrations.AddEmailSchedulerTrackingFields do
  use Ecto.Migration

  def change do
    alter table(:emails) do
      # Email tracking fields for EmailScheduler
      add :email_type, :string
      add :entity_type, :string
      add :entity_id, :string
      add :swoosh_message_id, :string
      add :delivery_status, :string
      add :delivered_at, :utc_datetime
      add :error_message, :text
    end

    create index(:emails, [:email_type])
    create index(:emails, [:entity_type, :entity_id])
    create index(:emails, [:swoosh_message_id])
    create index(:emails, [:delivery_status])
  end
end
