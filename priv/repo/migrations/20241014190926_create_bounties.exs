defmodule Algora.Repo.Migrations.CreateBounties do
  use Ecto.Migration

  def change do
    create table(:bounties) do
      add :amount, :decimal, null: false
      add :currency, :string, null: false
      add :task_id, references(:tasks, on_delete: :restrict), null: false
      add :user_id, references(:users, on_delete: :restrict)

      timestamps()
    end

    create index(:bounties, [:task_id])
    create index(:bounties, [:user_id])
  end
end
