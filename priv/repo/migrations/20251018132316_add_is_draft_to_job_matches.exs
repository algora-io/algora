defmodule Algora.Repo.Migrations.AddIsDraftToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :is_draft, :boolean, default: false, null: false
    end
  end
end
