defmodule Algora.Repo.Migrations.AddContractTypeToBounties do
  use Ecto.Migration

  def change do
    alter table(:bounties) do
      add :contract_type, :string
    end
  end
end
