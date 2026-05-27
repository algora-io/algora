defmodule Algora.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table(:companies, primary_key: false) do
      add :id, :text, primary_key: true
      add :name, :citext, null: false
      add :logo_url, :text
      add :linkedin_id, :text
      timestamps()
    end

    create unique_index(:companies, [:name], name: :companies_name_idx, concurrently: true)
  end

  def down do
    drop table(:companies)
  end
end
