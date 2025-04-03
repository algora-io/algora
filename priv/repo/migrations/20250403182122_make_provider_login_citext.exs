defmodule Algora.Repo.Migrations.MakeProviderLoginCitext do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE users DROP COLUMN name")

    alter table(:users) do
      modify :provider_login, :citext
    end

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

  def down do
    execute("ALTER TABLE users DROP COLUMN name")

    alter table(:users) do
      modify :provider_login, :string
    end

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
