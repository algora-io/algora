defmodule Algora.Repo.Migrations.CreateUserMedia do
  use Ecto.Migration

  def change do
    create table(:user_media) do
      add :url, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:user_media, [:user_id])
  end
end
