defmodule Algora.Repo.Migrations.AddTeamToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :team, :string, null: true
    end
  end
end
