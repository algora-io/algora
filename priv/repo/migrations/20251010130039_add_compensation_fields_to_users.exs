defmodule Algora.Repo.Migrations.AddCompensationFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Company funding information
      add :latest_funding_round, :string
      add :amount_raised, :money_with_currency
      add :company_valuation, :money_with_currency
    end
  end
end
