defmodule Algora.Repo.Migrations.AddCandidatesIndexLiveIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create_if_not_exists index(
                          :job_matches,
                          [:candidate_approved_at, :id, :status],
                          name: :job_matches_candidates_index_live_idx,
                          where:
                            "dropped = false AND company_discarded_at IS NULL AND provider_application_id IS NULL AND candidate_approved_at IS NOT NULL",
                          concurrently: true
                        )

    create_if_not_exists index(
                          :job_interviews,
                          [:job_posting_id, :user_id],
                          name: :job_interviews_earliest_start_date_set_idx,
                          where: "earliest_start_date IS NOT NULL",
                          concurrently: true
                        )
  end
end
