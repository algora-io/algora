defmodule Algora.Repo.Migrations.AddProviderNotesMetaToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :provider_notes_meta, :map, default: %{}
    end
  end
end
