defmodule Algora.Repo.Migrations.AddCustomQuestionAnswerToJobInterviews do
  use Ecto.Migration

  def change do
    alter table(:job_interviews) do
      add :custom_question_answer, :text
    end
  end
end
