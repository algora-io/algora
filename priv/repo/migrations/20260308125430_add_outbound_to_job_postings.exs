defmodule Algora.Repo.Migrations.AddOutboundToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :outbound, :boolean, default: true, null: false
    end
  end
end
