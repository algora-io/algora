defmodule Algora.Repo.Migrations.CreateBounties do
  use Ecto.Migration

  def change do
    create table(:bounties) do
      add :amount, :money_with_currency
      add :ticket_id, references(:tickets, on_delete: :restrict), null: false
      add :owner_id, references(:users, on_delete: :restrict), null: false
      add :creator_id, references(:users, on_delete: :restrict)

      timestamps()
    end

    create index(:bounties, [:ticket_id])
    create index(:bounties, [:owner_id])
    create index(:bounties, [:creator_id])
  end
end
