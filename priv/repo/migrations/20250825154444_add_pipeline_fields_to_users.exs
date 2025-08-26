defmodule Algora.Repo.Migrations.AddPipelineFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :last_dm_date, :utc_datetime_usec
      add :candidate_notes, :text
    end
  end
end