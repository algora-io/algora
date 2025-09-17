defmodule Algora.Repo.Migrations.AddTalentQueryOptimizationIndexes do
  use Ecto.Migration

  def change do
    # 1. Core talent filtering indexes (skip status - already exists)
    create index(:talents, [:user_id, :status])
    create index(:talents, [:source], where: "source IS NOT NULL")

    # 2. User preference and location indexes for complex filtering
    create index(:users, [:location_iso_lvl4], where: "location_iso_lvl4 IS NOT NULL")
    create index(:users, [:open_to_relocate_sf], where: "open_to_relocate_sf = true")
    create index(:users, [:open_to_relocate_ny], where: "open_to_relocate_ny = true")
    create index(:users, [:open_to_relocate_country], where: "open_to_relocate_country = true")
    create index(:users, [:open_to_relocate_world], where: "open_to_relocate_world = true")

    # 3. Composite index for common state filtering patterns
    create index(:users, [:country, :location_iso_lvl4, :open_to_relocate_sf, :open_to_relocate_ny],
                 name: "idx_users_location_preferences")

    # 4. LinkedIn and employment info indexes
    create index(:users, [:linkedin_url], where: "linkedin_url IS NOT NULL")
    create index(:users, [:linkedin_url_attempted], where: "linkedin_url_attempted = true")
    create index(:users, [:linkedin_meta_attempted], where: "linkedin_meta_attempted = true")

    # 5. Email and contact filtering (skip email - already exists, add internal_email)
    create index(:users, [:internal_email], where: "internal_email IS NOT NULL")

    # 6. Complex email existence check optimization
    create index(:users, [:email, :internal_email, "(provider_meta ->> 'email')"],
                 name: "idx_users_email_existence",
                 where: "email IS NOT NULL OR internal_email IS NOT NULL OR provider_meta ->> 'email' IS NOT NULL")

    # 7. System tags GIN index for array operations
    create index(:users, [:system_tags], using: :gin, where: "system_tags IS NOT NULL AND array_length(system_tags, 1) > 0")

    # 8. Language contributions optimization
    create index(:language_contributions, [:user_id, :language, :prs],
                 name: "idx_language_contributions_user_lang_prs")

    # 9. User contributions with repository optimization
    create index(:user_contributions, [:user_id, :repository_id, :contribution_count],
                 name: "idx_user_contributions_complete")

    # 10. Repository tech stack and topics for scoring
    create index(:repositories, [:tech_stack], using: :gin, where: "array_length(tech_stack, 1) > 0")
    create index(:repositories, [:topics], using: :gin, where: "array_length(topics, 1) > 0")
    create index(:repositories, [:stargazers_count, :tech_stack],
                 name: "idx_repositories_stars_tech_stack")

    # 11. Job matches comprehensive index for EXISTS queries
    create index(:job_matches, [:user_id, :status, :candidate_discarded_at, :candidate_approved_at, :candidate_bookmarked_at],
                 name: "idx_job_matches_user_status_complete")

    # 12. Stargazers optimization (skip user_id, repository_id - already exist individually and as composite)

    # 13. Min compensation with NULL handling for sorting
    create index(:users, [:min_compensation], where: "min_compensation IS NOT NULL")

    # 14. Import source filtering
    create index(:users, [:import_source], where: "import_source IS NOT NULL")

    # 15. Provider meta company optimization (skip - similar GIN index already exists)

    # 16. Timestamp-based filtering and sorting
    create index(:users, [:updated_at])
    create index(:talents, [:inserted_at])
    create index(:talents, [:updated_at])

    # 17. Complex composite index for main talent query patterns
    create index(:talents, [:status, :user_id, :inserted_at],
                 name: "idx_talents_status_user_inserted")

    # 18. Composite index for user filtering with timestamps
    create index(:users, [:type, :country, :open_to_new_role, :last_job_match_email_at],
                 name: "idx_users_pipeline_filtering",
                 where: "type = 'individual'")
  end
end