defmodule Algora.Repo.Migrations.DropActivitiesTables do
  use Ecto.Migration

  def change do
    drop table(:job_activities)
    drop table(:project_activities)
  end
end
