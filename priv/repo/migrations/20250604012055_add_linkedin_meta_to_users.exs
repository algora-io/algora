defmodule Algora.Repo.Migrations.AddLinkedinMetaToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :linkedin_meta, :map
    end
  end
end
