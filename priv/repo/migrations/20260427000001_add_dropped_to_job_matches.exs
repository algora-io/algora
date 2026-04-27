defmodule Algora.Repo.Migrations.AddDroppedToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :dropped, :boolean, default: false, null: false
    end
  end
end
