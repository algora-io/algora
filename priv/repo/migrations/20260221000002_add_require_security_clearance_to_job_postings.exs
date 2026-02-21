defmodule Algora.Repo.Migrations.AddRequireSecurityClearanceToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :require_security_clearance, :boolean, default: false, null: false
    end
  end
end
