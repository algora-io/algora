defmodule Algora.Repo.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings, primary_key: false) do
      add :key, :string, primary_key: true
      add :value, :map
      timestamps()
    end
  end
end
