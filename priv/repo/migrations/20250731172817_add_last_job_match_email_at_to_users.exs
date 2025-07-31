defmodule Algora.Repo.Migrations.AddLastJobMatchEmailAtToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :last_job_match_email_at, :utc_datetime_usec
    end
  end
end
