defmodule Algora.Repo.Migrations.AddOptimizedExcludeOrgIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    # Optimized index for exclude_org_handle job_matches EXISTS query
    # Supports: WHERE jm.user_id = ? AND jm.job_posting_id = ANY(?)
    # This index covers the optimized query pattern that uses pre-computed job_posting_ids
    create_if_not_exists index(:job_matches, [:user_id, :job_posting_id],
                           concurrently: true,
                           name: :job_matches_user_job_posting_optimized_idx
                         )

    # Optimized index for exclude_org_handle job_interviews EXISTS query
    # Supports: WHERE ji.user_id = ? AND ji.status != 'initial' AND ji.job_posting_id = ANY(?)
    # This ensures the status filter can be efficiently applied
    create_if_not_exists index(:job_interviews, [:user_id, :status, :job_posting_id],
                           concurrently: true,
                           name: :job_interviews_user_status_job_posting_optimized_idx
                         )
  end
end
