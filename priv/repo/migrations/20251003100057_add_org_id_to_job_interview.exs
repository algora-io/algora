defmodule Algora.Repo.Migrations.AddOrgIdToJobInterview do
  use Ecto.Migration

  def up do
    # Add org_id as nullable first
    alter table(:job_interviews) do
      add :org_id, references(:users, on_delete: :delete_all, type: :string), null: true
    end

    # Backfill org_id from job_posting.user_id
    execute """
    UPDATE job_interviews
    SET org_id = job_postings.user_id
    FROM job_postings
    WHERE job_interviews.job_posting_id = job_postings.id
    """

    # Make org_id non-nullable
    alter table(:job_interviews) do
      modify :org_id, :string, null: false, from: {:string, null: true}
    end

    # Add unique index on (user_id, org_id)
    create unique_index(:job_interviews, [:user_id, :org_id])
  end

  def down do
    drop index(:job_interviews, [:user_id, :org_id])

    alter table(:job_interviews) do
      remove :org_id
    end
  end
end
