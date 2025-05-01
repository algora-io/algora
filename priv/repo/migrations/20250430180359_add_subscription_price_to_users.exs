defmodule Algora.Repo.Migrations.AddSubscriptionPriceToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :subscription_price, :money_with_currency
    end
  end
end
