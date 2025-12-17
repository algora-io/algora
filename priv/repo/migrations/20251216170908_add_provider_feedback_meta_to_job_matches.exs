defmodule Algora.Repo.Migrations.AddProviderFeedbackMetaToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :provider_feedback_meta, :map, default: "{}"
    end
  end
end
