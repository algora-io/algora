defmodule Algora.Repo.Migrations.UpdateUserNameDefinition do
  use Ecto.Migration

  def change do
    execute("ALTER TABLE users DROP COLUMN name;")

    execute("""
    ALTER TABLE users ADD COLUMN name VARCHAR GENERATED ALWAYS AS (
      COALESCE(
        NULLIF(TRIM(display_name), ''),
        handle,
        provider_login
      )
    ) STORED;
    """)
  end
end
