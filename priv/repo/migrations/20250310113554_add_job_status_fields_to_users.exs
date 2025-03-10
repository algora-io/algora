defmodule Algora.Repo.Migrations.AddJobStatusFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :seeking_bounties, :boolean, default: false
      add :seeking_contracts, :boolean, default: false
      add :seeking_jobs, :boolean, default: false
      add :hiring, :boolean, default: false
    end
  end
end
