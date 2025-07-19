defmodule Algora.Repo.Migrations.CreateJobInterviews do
  use Ecto.Migration

  def change do
    create table(:job_interviews) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :job_posting_id, references(:job_postings, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :notes, :text
      add :scheduled_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec

      timestamps()
    end

    create index(:job_interviews, [:user_id])
    create index(:job_interviews, [:job_posting_id])
    create index(:job_interviews, [:status])
  end
end
