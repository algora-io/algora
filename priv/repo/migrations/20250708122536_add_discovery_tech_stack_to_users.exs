defmodule Algora.Repo.Migrations.AddDiscoveryTechStackToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :discovery_tech_stack, {:array, :citext}, default: []
    end

    execute("UPDATE users SET discovery_tech_stack = tech_stack WHERE tech_stack != '{}'")
  end

  def down do
    alter table(:users) do
      remove :discovery_tech_stack
    end
  end
end
