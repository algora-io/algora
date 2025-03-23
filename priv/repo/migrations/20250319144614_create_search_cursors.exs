defmodule Algora.Repo.Migrations.CreateSearchCursors do
  use Ecto.Migration

  def change do
    create table(:search_cursors) do
      add :provider, :string, null: false
      add :timestamp, :utc_datetime_usec, null: false
      add :last_polled_at, :utc_datetime_usec

      timestamps()
    end

    create unique_index(:search_cursors, [:provider])
  end
end
