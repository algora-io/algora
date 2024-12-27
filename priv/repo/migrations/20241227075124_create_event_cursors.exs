defmodule Algora.Repo.Migrations.CreateEventCursors do
  use Ecto.Migration

  def change do
    create table(:event_cursors) do
      add :provider, :string, null: false
      add :repo_owner, :string, null: false
      add :repo_name, :string, null: false
      add :last_event_id, :string
      add :last_polled_at, :utc_datetime_usec

      timestamps()
    end

    create unique_index(:event_cursors, [:provider, :repo_owner, :repo_name])
  end
end
