defmodule Algora.Repo.Migrations.AddAutopayDisabledToBounties do
  use Ecto.Migration

  def change do
    alter table(:bounties) do
      add :autopay_disabled, :boolean, default: false, null: false
    end
  end
end
