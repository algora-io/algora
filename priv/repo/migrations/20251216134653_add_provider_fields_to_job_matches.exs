defmodule Algora.Repo.Migrations.AddProviderFieldsToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :provider_candidate_id, :string
      add :provider_application_id, :string
      add :provider_candidate_meta, :map
      add :provider_application_meta, :map
    end
  end
end
