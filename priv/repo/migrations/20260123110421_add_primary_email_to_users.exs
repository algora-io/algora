defmodule Algora.Repo.Migrations.AddPrimaryEmailToUsers do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    # Create expression index for fast email lookups
    # This gives same performance as generated column without table rewrite
    # Priority: internal_email > email > provider_meta->>'email'
    execute """
    CREATE INDEX CONCURRENTLY IF NOT EXISTS users_primary_email_index
    ON users (COALESCE(internal_email, email, provider_meta->>'email'))
    """
  end

  def down do
    execute "DROP INDEX IF EXISTS users_primary_email_index"
  end
end
