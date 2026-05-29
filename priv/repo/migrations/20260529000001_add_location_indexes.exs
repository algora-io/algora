defmodule Algora.Repo.Migrations.AddLocationIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create_if_not_exists index(:users, ["lower(location)"],
                           where: "location IS NOT NULL AND location_meta IS NULL",
                           name: :users_lower_location_pending_idx,
                           concurrently: true
                         )

    create_if_not_exists index(:users, ["lower(location)"],
                           where: "location IS NOT NULL AND location_meta IS NOT NULL",
                           name: :users_lower_location_geocoded_idx,
                           concurrently: true
                         )
  end
end
