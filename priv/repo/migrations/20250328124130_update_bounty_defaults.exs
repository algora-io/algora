defmodule Algora.Repo.Migrations.UpdateBountyDefaults do
  use Ecto.Migration

  def up do
    alter table(:bounties) do
      modify :visibility, :string, default: "community"
    end

    alter table(:users) do
      modify :bounty_mode, :string, default: "community"
      modify :fee_pct, :integer, null: false, default: 9
    end
  end

  def down do
    alter table(:bounties) do
      modify :visibility, :string, default: "public"
    end

    alter table(:users) do
      modify :bounty_mode, :string, default: "public"
      modify :fee_pct, :integer, null: false, default: 19
    end
  end
end
