defmodule Algora.Repo.Migrations.CreateTimesheets do
  use Ecto.Migration

  def change do
    create table(:timesheets) do
      add :hours_worked, :integer, null: false
      add :start_date, :utc_datetime_usec, null: false
      add :end_date, :utc_datetime_usec, null: false
      add :description, :text

      add :contract_id, references(:contracts, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:timesheets, [:contract_id])
  end
end
