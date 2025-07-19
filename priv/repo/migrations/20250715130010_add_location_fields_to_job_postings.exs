defmodule Algora.Repo.Migrations.AddLocationFieldsToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :location_meta, :map
      add :location_iso_lvl4, :string
    end
  end
end
