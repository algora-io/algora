defmodule Algora.Repo.Migrations.CreateInvalidRepos do
  use Ecto.Migration

  def change do
    create table(:invalid_repos) do
      add :owner, :string, null: false
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:invalid_repos, [:owner, :name])
  end
end
