defmodule Algora.Repo.Migrations.AddCustomSortingToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :custom_sort_order, :integer
    end

    create index(:job_matches, [:custom_sort_order])
  end
end
