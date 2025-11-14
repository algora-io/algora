defmodule Algora.Repo.Migrations.ChangeJobPostingsLocationToText do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      modify :location, :text
    end
  end
end
