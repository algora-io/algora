defmodule Algora.Repo.Migrations.AddAnonymizeToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :anonymize, :boolean, default: true
    end

    create index(:job_matches, [:anonymize])
  end
end
