defmodule Algora.Repo.Migrations.CreateUserHeatmaps do
  use Ecto.Migration

  def change do
    create table(:user_heatmaps) do
      add :data, :map, null: false

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:user_heatmaps, [:user_id])
  end
end
