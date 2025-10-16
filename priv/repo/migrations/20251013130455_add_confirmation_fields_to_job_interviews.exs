defmodule Algora.Repo.Migrations.AddConfirmationFieldsToJobInterviews do
  use Ecto.Migration

  def change do
    alter table(:job_interviews) do
      add :willing_to_relocate, :boolean
      add :work_auth_us, :boolean
      add :resume_url, :text
      add :earliest_start_date, :date
    end
  end
end
