defmodule Algora.Repo.Migrations.DropObsoleteCursors do
  use Ecto.Migration

  def change do
    drop table(:comment_cursors)
    drop table(:event_cursors)
  end
end
