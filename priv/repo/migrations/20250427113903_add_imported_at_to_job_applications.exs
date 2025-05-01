defmodule Algora.Repo.Migrations.AddImportedAtToJobApplications do
  use Ecto.Migration

  def change do
    alter table(:job_applications) do
      add :imported_at, :utc_datetime_usec
    end
  end
end
