defmodule Algora.Repo.Migrations.AddOpenToRelocateLocalIndexToUsers do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:users, [:open_to_relocate_local], concurrently: true)
  end
end
