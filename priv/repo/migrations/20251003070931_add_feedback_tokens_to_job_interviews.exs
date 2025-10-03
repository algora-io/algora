defmodule Algora.Repo.Migrations.AddFeedbackTokensToJobInterviews do
  use Ecto.Migration

  def change do
    alter table(:job_interviews) do
      add :company_feedback_token, :string
      add :candidate_feedback_token, :string
    end

    create unique_index(:job_interviews, [:company_feedback_token])
    create unique_index(:job_interviews, [:candidate_feedback_token])
  end
end
