defmodule Algora.Repo.Migrations.AddSystemBioFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :system_bio, :text
      add :system_bio_meta, :map, default: %{}
    end
  end
end
