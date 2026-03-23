defmodule Algora.Repo.Migrations.AddContributorAndDownloadCountsToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :contributors_count, :integer
      add :downloads_count, :integer
    end
  end
end
