defmodule Algora.Repo.Migrations.AddLocationFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :location_meta, :map
      add :location_iso_lvl4, :string
    end
  end
end
