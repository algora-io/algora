defmodule Algora.Repo.Migrations.AddCandidateActionTimestampsToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :approved_at, :utc_datetime_usec
      add :bookmarked_at, :utc_datetime_usec
      add :discarded_at, :utc_datetime_usec
    end
  end
end
