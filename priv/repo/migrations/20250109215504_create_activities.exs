defmodule Algora.Repo.Migrations.CreateActivities do
  use Ecto.Migration

  require Algora.Activities

  @tables [
    "identity_activities",
    "user_activities",
    "attempt_activities",
    "bonus_activities",
    "bounty_activities",
    "claim_activities",
    "tip_activities",
    "message_activities",
    "thread_activities",
    "contract_activities",
    "timesheet_activities",
    "application_activities",
    "job_activities",
    "account_activities",
    "customer_activities",
    "payment_method_activities",
    "platform_transaction_activities",
    "transaction_activities",
    "project_activities",
    "review_activities",
    "installation_activities",
    "ticket_activities",
    "repository_activities"
  ]

  def change do
    Enum.each(@tables, fn table_name ->
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
