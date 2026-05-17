defmodule Algora.Repo.Migrations.AddLinkedinProfileColumns do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    alter table(:users) do
      add_if_not_exists :linkedin_profile, :map
      add_if_not_exists :linkedin_profile_raw, :text
    end

    drop_if_exists index(:users, [], name: :idx_users_backfill_linkedin_profile)

    execute """
    CREATE INDEX CONCURRENTLY idx_users_backfill_linkedin_profile ON users USING btree (id)
    INCLUDE (open_to_ic, open_to_manager, open_to_fulltime, open_to_contract, country)
    WHERE
      type = 'individual'
      AND provider_login IS NOT NULL
      AND opt_out_algora = false
      AND open_to_new_role = true
      AND linkedin_profile_raw IS NOT NULL
      AND linkedin_profile IS NULL
    """
  end

  def down do
    drop_if_exists index(:users, [], name: :idx_users_backfill_linkedin_profile)

    execute """
    CREATE INDEX CONCURRENTLY idx_users_backfill_linkedin_profile ON users USING btree (id)
    INCLUDE (open_to_ic, open_to_manager, open_to_fulltime, open_to_contract, country)
    WHERE
      type = 'individual'
      AND provider_login IS NOT NULL
      AND opt_out_algora = false
      AND open_to_new_role = true
      AND (linkedin_meta -> 'profile_raw') IS NOT NULL
      AND (linkedin_meta -> 'profile') IS NULL
    """

    alter table(:users) do
      remove :linkedin_profile
      remove :linkedin_profile_raw
    end
  end
end
