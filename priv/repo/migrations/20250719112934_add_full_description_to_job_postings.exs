defmodule Algora.Repo.Migrations.AddFullDescriptionToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :full_description, :text
    end
  end
end
