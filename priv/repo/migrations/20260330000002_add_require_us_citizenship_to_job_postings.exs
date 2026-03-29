defmodule Algora.Repo.Migrations.AddRequireUsCitizenshipToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :require_us_citizenship, :boolean, default: false, null: false
    end
  end
end
