defmodule Algora.Repo.Migrations.AddContractSignedIndexToUsers do
  use Ecto.Migration

  def change do
    create index(:users, [:contract_signed])
  end
end
