defmodule Algora.Repo.Migrations.AddOtherInterviewsToJobInterviews do
  use Ecto.Migration

  def change do
    alter table(:job_interviews) do
      add :other_interviews, :text
    end
  end
end
