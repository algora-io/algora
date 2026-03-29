defmodule Algora.Repo.Migrations.AddOpenToInpersonToJobInterviews do
  use Ecto.Migration

  def change do
    alter table(:job_interviews) do
      add :open_to_inperson, :boolean
    end
  end
end
