defmodule Algora.Repo.Migrations.AddFeedbackToJobInterviews do
  use Ecto.Migration

  def change do
    alter table(:job_interviews) do
      add :company_feedback, :text
      add :candidate_feedback, :text
    end
  end
end
