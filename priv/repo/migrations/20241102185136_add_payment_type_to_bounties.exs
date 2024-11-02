defmodule Algora.Repo.Migrations.AddPaymentTypeToBounties do
  use Ecto.Migration

  def change do
    alter table(:bounties) do
      add :payment_type, :string, default: "fixed"
    end
  end
end
