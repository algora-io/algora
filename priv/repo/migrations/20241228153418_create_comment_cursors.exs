defmodule Algora.Repo.Migrations.CreateCommentCursors do
  use Ecto.Migration

  def change do
    create table(:comment_cursors) do
      add :provider, :string, null: false
      add :repo_owner, :string, null: false
      add :repo_name, :string, null: false
      add :timestamp, :utc_datetime_usec, null: false
      add :last_polled_at, :utc_datetime_usec
      add :last_comment_id, :string

      timestamps()
    end

    create unique_index(:comment_cursors, [:provider, :repo_owner, :repo_name])
  end
end
