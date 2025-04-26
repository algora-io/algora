defmodule Algora.Repo.Migrations.CreateUserContributions do
  use Ecto.Migration

  def change do
    create table(:user_contributions) do
      add :contribution_count, :integer, null: false, default: 0
      add :last_fetched_at, :utc_datetime_usec, null: false

      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :repository_id, references(:repositories, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:user_contributions, [:user_id])
    create index(:user_contributions, [:repository_id])
    create unique_index(:user_contributions, [:user_id, :repository_id])

    alter table(:repositories) do
      add :stargazers_count, :integer, null: false, default: 0
    end

    # Backfill stargazers_count from provider_meta
    execute """
    UPDATE repositories
    SET stargazers_count = COALESCE((provider_meta->>'stargazers_count')::integer, 0)
    """
  end
end
