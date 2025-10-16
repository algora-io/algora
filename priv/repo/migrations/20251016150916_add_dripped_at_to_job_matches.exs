defmodule Algora.Repo.Migrations.AddDrippedAtToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :dripped_at, :utc_datetime_usec
    end
  end
end
