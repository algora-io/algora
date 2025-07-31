defmodule Algora.Repo.Migrations.SplitJobMatchTimestampsBySide do
  use Ecto.Migration

  def up do
    # Add new timestamp fields for company and candidate sides
    alter table(:job_matches) do
      add :company_approved_at, :utc_datetime_usec
      add :company_bookmarked_at, :utc_datetime_usec
      add :company_discarded_at, :utc_datetime_usec
      add :candidate_approved_at, :utc_datetime_usec
      add :candidate_bookmarked_at, :utc_datetime_usec
      add :candidate_discarded_at, :utc_datetime_usec
    end

    # Migrate existing data - all existing timestamps are from company side
    execute """
    UPDATE job_matches 
    SET company_approved_at = approved_at,
        company_bookmarked_at = bookmarked_at,
        company_discarded_at = discarded_at
    WHERE approved_at IS NOT NULL 
       OR bookmarked_at IS NOT NULL 
       OR discarded_at IS NOT NULL
    """

    # Drop the obsolete fields
    alter table(:job_matches) do
      remove :approved_at
      remove :bookmarked_at
      remove :discarded_at
    end
  end

  def down do
    # Add back the original fields
    alter table(:job_matches) do
      add :approved_at, :utc_datetime_usec
      add :bookmarked_at, :utc_datetime_usec
      add :discarded_at, :utc_datetime_usec
    end

    # Migrate data back from company fields
    execute """
    UPDATE job_matches 
    SET approved_at = company_approved_at,
        bookmarked_at = company_bookmarked_at,
        discarded_at = company_discarded_at
    WHERE company_approved_at IS NOT NULL 
       OR company_bookmarked_at IS NOT NULL 
       OR company_discarded_at IS NOT NULL
    """

    # Drop the new fields
    alter table(:job_matches) do
      remove :company_approved_at
      remove :company_bookmarked_at
      remove :company_discarded_at
      remove :candidate_approved_at
      remove :candidate_bookmarked_at
      remove :candidate_discarded_at
    end
  end
end