defmodule Algora.Repo.Migrations.AddLanguageContributionsSyncedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :language_contributions_synced, :boolean, default: false, null: false
    end
  end
end
