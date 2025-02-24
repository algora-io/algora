defmodule Algora.Repo.Migrations.AddIdempotencyKeyToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :idempotency_key, :string
    end

    create unique_index(:transactions, [:idempotency_key])
  end
end
