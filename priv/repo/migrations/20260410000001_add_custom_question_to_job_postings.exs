defmodule Algora.Repo.Migrations.AddCustomQuestionToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :custom_question, :text
    end
  end
end
