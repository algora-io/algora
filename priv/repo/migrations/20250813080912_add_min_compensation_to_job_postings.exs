defmodule Algora.Repo.Migrations.AddMinCompensationToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :min_compensation, :money_with_currency
    end
  end
end
