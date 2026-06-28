defmodule Algora.Repo.Migrations.AddEmailsToUsers do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    alter table(:users) do
      add :emails, {:array, :string}
    end

    execute(
      """
      CREATE INDEX CONCURRENTLY IF NOT EXISTS users_emails_idx ON users (id)
      INCLUDE (open_to_ic, open_to_manager, open_to_fulltime, open_to_contract, country)
      WHERE emails IS NULL
        AND email IS NULL
        AND internal_email IS NULL
        AND provider_login IS NOT NULL
        AND (provider_meta ->> 'email') IS NULL
        AND type = 'individual'
        AND opt_out_algora = FALSE
        AND open_to_new_role = TRUE
      """,
      "DROP INDEX CONCURRENTLY IF EXISTS users_emails_idx"
    )
  end
end
