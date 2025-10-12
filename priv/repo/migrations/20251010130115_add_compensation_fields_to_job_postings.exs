defmodule Algora.Repo.Migrations.AddCompensationFieldsToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      # Equity range (stored as percentages, e.g., 0.25 for 0.25%)
      add :min_equity, :decimal, precision: 10, scale: 4
      add :max_equity, :decimal, precision: 10, scale: 4
    end
  end
end
