defmodule Algora.Repo.Migrations.AddPipelineIndexes do
  use Ecto.Migration

  def change do
    # Critical indexes for pipeline performance
    create index(:users, [:last_job_match_email_at], where: "last_job_match_email_at IS NOT NULL")
    create index(:users, [:last_dm_date], where: "last_dm_date IS NOT NULL")
    create index(:users, [:country], where: "country IS NOT NULL")
    create index(:users, [:open_to_new_role], where: "open_to_new_role = true")
    create index(:users, [:type], where: "type = 'individual'")

    # Composite index for the main query ordering
    create index(
             :users,
             [
               "GREATEST(last_job_match_email_at, last_dm_date)",
               :id
             ],
             where:
               "last_job_match_email_at IS NOT NULL AND open_to_new_role = true AND type = 'individual'"
           )

    # Job matches indexes for EXISTS queries
    create index(:job_matches, [:user_id, :candidate_discarded_at, :candidate_approved_at])
    create index(:job_matches, [:user_id, :candidate_discarded_at, :candidate_bookmarked_at])
  end
end
