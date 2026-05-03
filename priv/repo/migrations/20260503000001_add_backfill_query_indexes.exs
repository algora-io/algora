defmodule Algora.Repo.Migrations.AddBackfillQueryIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    # For: count_talents(include_all?: true, backfill_resume: true, has_resume: true)
    # Filters: resume_url IS NOT NULL AND resume IS NULL (plus base filters)
    execute """
    CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_backfill_resume
    ON users (id)
    WHERE type = 'individual'
      AND provider_login IS NOT NULL
      AND opt_out_algora = false
      AND open_to_new_role = true
      AND resume_url IS NOT NULL
      AND resume IS NULL
    """

    # For: count_talents(include_all?: true, backfill_linkedin_profile: true, has_linkedin: true)
    # Filters: linkedin_meta->'profile_raw' IS NOT NULL AND linkedin_meta->'profile' IS NULL (plus base filters)
    execute """
    CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_backfill_linkedin_profile
    ON users (id)
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
  end
end
