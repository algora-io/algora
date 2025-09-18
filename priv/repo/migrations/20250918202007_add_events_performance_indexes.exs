defmodule Algora.Repo.Migrations.AddEventsPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Composite index for the main query that filters by date and type
    create index(:events, [:inserted_at, :type], name: :events_inserted_at_type_composite_index)

    # Composite index for candidates page visit queries with payload JSON access
    create index(:events, [:type, :inserted_at], where: "type = 'candidates_page_visit'", name: :events_candidates_visits_index)

    # Composite index for profile page visit queries with payload JSON access
    create index(:events, [:type, :inserted_at], where: "type = 'profile_page_visit'", name: :events_profile_visits_index)

    # GIN index for JSON payload queries (for org_handle and target_user_id lookups)
    create index(:events, ["payload"], using: :gin, name: :events_payload_gin_index)
  end
end
