defmodule Algora.Repo.Migrations.CreateContracts do
  use Ecto.Migration

  def change do
    create table(:contracts) do
      add :status, :string, null: false
      add :sequence_number, :integer, null: false, default: 1
      add :hourly_rate, :money_with_currency, null: false
      add :hours_per_week, :integer, null: false
      add :start_date, :utc_datetime_usec, null: false
      add :end_date, :utc_datetime_usec
      add :original_contract_id, references(:contracts, on_delete: :nilify_all)
      add :client_id, references(:users, on_delete: :restrict), null: false
      add :contractor_id, references(:users, on_delete: :restrict)

      timestamps()
    end

    create index(:contracts, [:original_contract_id])
    create index(:contracts, [:client_id])
    create index(:contracts, [:contractor_id])
  end
end
