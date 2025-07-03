defmodule Algora.Repo.Migrations.CreateTalents do
  use Ecto.Migration

  def change do
    create table(:talents) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :source, :string
      add :metadata, :map

      timestamps()
    end

    create unique_index(:talents, [:user_id])
    create index(:talents, [:status])
  end
end
