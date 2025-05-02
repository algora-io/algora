defmodule Algora.Repo.Migrations.AddLocationCompensationSeniorityToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :location, :string
      add :compensation, :string
      add :seniority, :string
    end
  end
end
