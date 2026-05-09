defmodule Algora.Repo.Migrations.MakeBackfillIndexesCovering do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_users_backfill_resume"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_users_backfill_linkedin_profile"

    execute """
    CREATE INDEX CONCURRENTLY idx_users_backfill_resume
    ON users (id)
    INCLUDE (open_to_ic, open_to_manager, open_to_fulltime, open_to_contract, country)
    WHERE type = 'individual'
      AND provider_login IS NOT NULL
      AND opt_out_algora = false
      AND open_to_new_role = true
      AND resume_url IS NOT NULL
      AND resume IS NULL
    """

    execute """
    CREATE INDEX CONCURRENTLY idx_users_backfill_linkedin_profile
    ON users (id)
    INCLUDE (open_to_ic, open_to_manager, open_to_fulltime, open_to_contract, country)
    WHERE type = 'individual'
      AND provider_login IS NOT NULL
      AND opt_out_algora = false
      AND open_to_new_role = true
      AND (linkedin_meta -> 'profile_raw') IS NOT NULL
      AND (linkedin_meta -> 'profile') IS NULL
    """
  end

  def down do
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_users_backfill_resume"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_users_backfill_linkedin_profile"

    execute """
    CREATE INDEX CONCURRENTLY idx_users_backfill_resume
    ON users (id)
    WHERE type = 'individual'
      AND provider_login IS NOT NULL
      AND opt_out_algora = false
      AND open_to_new_role = true
      AND resume_url IS NOT NULL
      AND resume IS NULL
    """

    execute """
    CREATE INDEX CONCURRENTLY idx_users_backfill_linkedin_profile
    ON users (id)
    WHERE type = 'individual'
      AND provider_login IS NOT NULL
      AND opt_out_algora = false
      AND open_to_new_role = true
      AND (linkedin_meta -> 'profile_raw') IS NOT NULL
      AND (linkedin_meta -> 'profile') IS NULL
    """
  end
end
