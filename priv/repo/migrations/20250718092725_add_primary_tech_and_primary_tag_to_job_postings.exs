defmodule Algora.Repo.Migrations.AddPrimaryTechAndPrimaryTagToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :primary_tech, :string
      add :primary_tag, :string
    end
  end
end
