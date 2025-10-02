defmodule Algora.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Index for provider_meta->>'followers' queries (used in talent matching)
    create index(:users, ["((provider_meta->>'followers')::int)"], name: :users_provider_meta_followers_idx)

    # Index for country filtering (frequently used in candidates/talents queries)
    create index(:users, [:country], where: "country IS NOT NULL", name: :users_country_idx)

    # Index for location_iso_lvl4 filtering
    create index(:users, [:location_iso_lvl4], where: "location_iso_lvl4 IS NOT NULL", name: :users_location_iso_lvl4_idx)

    # Index for min_compensation (used in sorting)
    create index(:users, [:min_compensation], where: "min_compensation IS NOT NULL", name: :users_min_compensation_idx)

    # Composite index for common talent queries
    create index(:users, [:country, :min_compensation],
      where: "country IS NOT NULL AND min_compensation IS NOT NULL",
      name: :users_country_min_compensation_idx)

    # Index for language_contributions user_id lookups
    create index(:language_contributions, [:user_id, :percentage], name: :language_contributions_user_id_percentage_idx)

    # Index for user_contributions filtering on user_id
    create index(:user_contributions, [:user_id, :contribution_count], name: :user_contributions_user_id_contribution_count_idx)
  end
end
