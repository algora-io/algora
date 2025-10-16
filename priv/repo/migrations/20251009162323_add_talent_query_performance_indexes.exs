defmodule Algora.Repo.Migrations.AddTalentQueryPerformanceIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    # Index 1: Composite index for job_postings subquery (org-specific job exclusion)
    # Improves: SELECT id FROM job_postings WHERE user_id IN (...)
    create_if_not_exists index(:job_postings, [:user_id, :id], concurrently: true)

    # Index 2: Composite index for job_interviews lookup (org-specific interview exclusion)
    # Improves: WHERE ji.user_id = ? AND ji.status != 'initial' AND ji.job_posting_id IN (...)
    create_if_not_exists index(:job_interviews, [:user_id, :status, :job_posting_id],
                           concurrently: true
                         )

    # Index 3: Composite index for users handle lookup in subquery
    # Improves: SELECT id FROM users WHERE handle = ?
    create_if_not_exists index(:users, [:handle, :id],
                           where: "handle IS NOT NULL",
                           concurrently: true
                         )

    # Index 4: Composite index for main pipeline filter combination
    # Improves the base WHERE clause filters applied to all talent queries
    create_if_not_exists index(
                           :users,
                           [:type, :open_to_new_role, :country, :provider_login],
                           where:
                             "type = 'individual' AND open_to_new_role = true AND provider_login IS NOT NULL",
                           concurrently: true,
                           name: :users_pipeline_base_idx
                         )

    # Index 5: Index for job_matches user_id lookup
    # Improves: WHERE jm.user_id = ? AND jm.job_posting_id IN (...)
    create_if_not_exists index(:job_matches, [:user_id, :job_posting_id], concurrently: true)
  end
end
