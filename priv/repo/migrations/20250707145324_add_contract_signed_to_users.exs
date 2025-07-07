defmodule Algora.Repo.Migrations.AddContractSignedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :contract_signed, :boolean, default: false
    end
  end
end
