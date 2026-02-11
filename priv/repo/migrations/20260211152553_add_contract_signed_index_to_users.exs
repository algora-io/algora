defmodule Algora.Repo.Migrations.AddContractSignedIndexToUsers do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:users, [:contract_signed], concurrently: true)
  end
end
