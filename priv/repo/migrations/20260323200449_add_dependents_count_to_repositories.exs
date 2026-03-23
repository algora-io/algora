defmodule Algora.Repo.Migrations.AddDependentsCountToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :dependents_count, :integer
    end
  end
end
