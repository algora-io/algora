defmodule Algora.Repo.Migrations.AddInternalNotesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :internal_notes, :text
    end
  end
end
