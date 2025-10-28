defmodule Algora.Repo.Migrations.AddEvalToJobMatches do
  use Ecto.Migration

  def change do
    alter table(:job_matches) do
      add :eval, :map
    end
  end
end
