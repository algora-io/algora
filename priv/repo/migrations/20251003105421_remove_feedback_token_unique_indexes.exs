defmodule Algora.Repo.Migrations.RemoveFeedbackTokenUniqueIndexes do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(:job_interviews, [:company_feedback_token])
    drop_if_exists unique_index(:job_interviews, [:candidate_feedback_token])
  end
end
