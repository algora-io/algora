defmodule Algora.Repo.Migrations.AddCountriesAndRegionsToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :countries, {:array, :string}, default: [], null: false
      add :regions, {:array, :string}, default: [], null: false
    end
  end
end
