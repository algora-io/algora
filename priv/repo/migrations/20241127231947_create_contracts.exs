defmodule Algora.Repo.Migrations.CreateContracts do
  use Ecto.Migration

  def change do
    create table(:contracts) do
      add :status, :string, null: false
      add :sequence_number, :integer, null: false, default: 1
      add :hourly_rate, :decimal, null: false
      add :hours_per_week, :integer, null: false
      add :start_date, :date, null: false
      add :end_date, :date
      add :total_paid, :decimal, null: false, default: 0

      add :original_contract_id, references(:contracts, on_delete: :nilify_all)
      add :client_id, references(:users, on_delete: :restrict), null: false
      add :provider_id, references(:users, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:contracts, [:original_contract_id])
    create index(:contracts, [:client_id])
    create index(:contracts, [:provider_id])
  end
end
