defmodule Algora.Repo.Migrations.CreateTimesheets do
  use Ecto.Migration

  def change do
    create table(:timesheets) do
      add :hours_worked, :integer, null: false
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :description, :text

      add :contract_id, references(:contracts, on_delete: :delete_all), null: false
      add :provider_id, references(:users, on_delete: :nilify_all), null: false

      timestamps()
    end

    create index(:timesheets, [:contract_id])
    create index(:timesheets, [:provider_id])
  end
end
