defmodule Algora.Repo.Migrations.AddStatesToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :states, {:array, :text}, default: []
    end
  end
end
