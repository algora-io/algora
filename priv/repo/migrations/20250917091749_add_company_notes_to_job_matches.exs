defmodule Algora.Repo.Migrations.AddCompanyNotesToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :company_notes, :text
    end
  end
end
