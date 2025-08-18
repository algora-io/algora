defmodule Algora.Repo.Migrations.CreateFollows do
  use Ecto.Migration

  def change do
    create table(:follows, primary_key: false) do
      add :id, :string, primary_key: true
      add :follower_id, references(:users, on_delete: :delete_all, type: :string), null: false
      add :followed_id, references(:users, on_delete: :delete_all, type: :string), null: false
      add :provider, :string, null: false, default: "github"
      add :provider_created_at, :utc_datetime_usec

      timestamps()
    end

    create unique_index(:follows, [:follower_id, :followed_id])
    create index(:follows, [:follower_id])
    create index(:follows, [:followed_id])
  end
end
