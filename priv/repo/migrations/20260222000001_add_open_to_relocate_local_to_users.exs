defmodule Algora.Repo.Migrations.AddOpenToRelocateLocalToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :open_to_relocate_local, :boolean, default: false
    end
  end
end
