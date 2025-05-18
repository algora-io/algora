defmodule Algora.Repo.Migrations.CreateStargazers do
  use Ecto.Migration

  def change do
    create table(:stargazers) do
      add :repository_id, references(:repositories, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    # Create an index for the foreign keys
    create index(:stargazers, [:repository_id])
    create index(:stargazers, [:user_id])

    # Create a unique index to prevent duplicate stars
    create unique_index(:stargazers, [:repository_id, :user_id])
  end
end
