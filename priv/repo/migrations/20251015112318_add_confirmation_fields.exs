defmodule Algora.Repo.Migrations.AddConfirmationFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :earliest_start_date, :date
    end

    alter table(:job_interviews) do
      add :favorite_thing, :text
    end
  end
end
