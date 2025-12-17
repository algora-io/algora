defmodule Algora.Repo.Migrations.AddProviderInterviewsMetaToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :provider_interviews_meta, :map, default: "{}"
    end
  end
end
