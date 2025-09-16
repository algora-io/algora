defmodule Algora.Repo.Migrations.AddImportSourceToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :import_source, :string, null: true
    end
  end
end
