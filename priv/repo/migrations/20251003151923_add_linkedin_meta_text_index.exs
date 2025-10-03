defmodule Algora.Repo.Migrations.AddLinkedinMetaTextIndex do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"
    # Drop old index that only covered 'experience' field
    execute "DROP INDEX IF EXISTS users_lower_idx"
    # Create new index covering entire linkedin_meta JSON
    execute "CREATE INDEX users_linkedin_meta_text_idx ON users USING gin(lower(linkedin_meta::text) gin_trgm_ops)"
  end

  def down do
    execute "DROP INDEX IF EXISTS users_linkedin_meta_text_idx"
    # Recreate old index
    execute "CREATE INDEX users_lower_idx ON users USING gin(lower(linkedin_meta ->> 'experience') gin_trgm_ops) WHERE linkedin_meta ->> 'experience' IS NOT NULL"
  end
end
