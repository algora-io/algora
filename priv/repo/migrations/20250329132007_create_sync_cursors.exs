defmodule Algora.Repo.Migrations.CreateSyncCursors do
  use Ecto.Migration

  def change do
    create table(:sync_cursors) do
      add :provider, :string, null: false
      add :resource, :string, null: false
      add :timestamp, :utc_datetime_usec, null: false
      add :last_polled_at, :utc_datetime_usec

      timestamps()
    end

    create unique_index(:sync_cursors, [:provider, :resource])
  end
end
