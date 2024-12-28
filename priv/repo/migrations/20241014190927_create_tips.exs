defmodule Algora.Repo.Migrations.CreateTips do
  use Ecto.Migration

  def change do
    create table(:tips) do
      add :amount, :money_with_currency
      add :status, :string, default: "open"
      add :ticket_id, references(:tickets, on_delete: :restrict)
      add :owner_id, references(:users, on_delete: :restrict), null: false
      add :creator_id, references(:users, on_delete: :restrict), null: false
      add :recipient_id, references(:users, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:tips, [:ticket_id])
    create index(:tips, [:owner_id])
    create index(:tips, [:creator_id])
    create index(:tips, [:recipient_id])
  end
end
