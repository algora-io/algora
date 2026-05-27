defmodule Algora.Repo.Migrations.DropInternalTagsFromUsers do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute "DROP INDEX CONCURRENTLY IF EXISTS users_internal_tags_nonempty_index"

    alter table(:users) do
      remove :internal_tags
    end
  end

  def down do
    alter table(:users) do
      add :internal_tags, {:array, :text}, default: [], null: false
    end

    execute """
    CREATE INDEX CONCURRENTLY IF NOT EXISTS users_internal_tags_nonempty_index
      ON users USING gin (internal_tags)
      WHERE internal_tags <> '{}'
    """
  end
end
