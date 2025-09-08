defmodule Algora.Repo.Migrations.AddAdminNoteToReplies do
  use Ecto.Migration

  def change do
    alter table(:replies) do
      add :admin_note, :text
    end
  end
end
