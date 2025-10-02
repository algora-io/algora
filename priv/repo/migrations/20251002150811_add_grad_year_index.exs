defmodule Algora.Repo.Migrations.AddGradYearIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:users, [:grad_year], where: "grad_year IS NOT NULL", concurrently: true)
  end
end
