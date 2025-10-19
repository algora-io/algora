defmodule Algora.Repo.Migrations.AddLockedToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :locked, :boolean, default: false, null: false
    end
  end
end
