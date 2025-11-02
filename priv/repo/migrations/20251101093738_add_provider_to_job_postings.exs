defmodule Algora.Repo.Migrations.AddProviderToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :provider, :string
      add :provider_id, :string
    end
  end
end
