defmodule Algora.Repo.Migrations.CreateContributors do
  use Ecto.Migration

  def change do
    create table(:contributors) do
      add :contributions, :integer, null: false, default: 0
      add :repository_id, references(:repositories, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:contributors, [:repository_id])
    create index(:contributors, [:user_id])

    create unique_index(:contributors, [:repository_id, :user_id],
             name: :contributors_repository_id_user_id_index
           )
  end
end
