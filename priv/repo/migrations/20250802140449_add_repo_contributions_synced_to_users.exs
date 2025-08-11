defmodule Algora.Repo.Migrations.AddRepoContributionsSyncedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :repo_contributions_synced, :boolean, default: false, null: false
    end
  end
end
