defmodule Algora.Repo.Migrations.AddHourlyRateToBounties do
  use Ecto.Migration

  def change do
    alter table(:bounties) do
      add :hourly_rate, :money_with_currency
    end
  end
end
