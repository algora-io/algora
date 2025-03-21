defmodule Algora.Repo.Migrations.AddSharedWithToBounties do
  use Ecto.Migration

  def change do
    alter table(:bounties) do
      add :shared_with, {:array, :citext}, default: "{}", null: false
    end
  end
end
