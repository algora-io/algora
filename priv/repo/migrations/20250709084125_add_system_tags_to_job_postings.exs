defmodule Algora.Repo.Migrations.AddSystemTagsToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :system_tags, {:array, :string}, default: []
    end
  end
end
