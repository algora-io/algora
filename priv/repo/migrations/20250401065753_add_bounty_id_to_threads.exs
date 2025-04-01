defmodule Algora.Repo.Migrations.AddBountyIdToThreads do
  use Ecto.Migration

  def change do
    alter table(:threads) do
      add :bounty_id, :string, null: true
    end

    create unique_index(:threads, [:bounty_id])
  end
end
