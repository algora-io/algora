defmodule Algora.Repo.Migrations.ChangeInternalTagsToTextArray do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute "DROP INDEX CONCURRENTLY IF EXISTS users_internal_tags_nonempty_index"

    # varchar and text are binary-coercible — no table rewrite, just metadata.
    # Skipped if already text[] (idempotent when run manually before deploy).
    execute """
    DO $$ BEGIN
      IF (SELECT atttypid::regtype FROM pg_attribute
          WHERE attrelid = 'users'::regclass AND attname = 'internal_tags') <> 'text[]'::regtype
      THEN
        ALTER TABLE users ALTER COLUMN internal_tags TYPE text[];
      END IF;
    END $$
    """

    execute """
    CREATE INDEX CONCURRENTLY IF NOT EXISTS users_internal_tags_nonempty_index
      ON users USING gin (internal_tags)
      WHERE internal_tags <> '{}'
    """
  end

  def down do
    execute "DROP INDEX CONCURRENTLY IF EXISTS users_internal_tags_nonempty_index"

    execute """
    DO $$ BEGIN
      IF (SELECT atttypid::regtype FROM pg_attribute
          WHERE attrelid = 'users'::regclass AND attname = 'internal_tags') <> 'character varying[]'::regtype
      THEN
        ALTER TABLE users ALTER COLUMN internal_tags TYPE varchar[];
      END IF;
    END $$
    """

    execute """
    CREATE INDEX CONCURRENTLY IF NOT EXISTS users_internal_tags_nonempty_index
      ON users USING gin (internal_tags)
      WHERE internal_tags <> '{}'
    """
  end
end
