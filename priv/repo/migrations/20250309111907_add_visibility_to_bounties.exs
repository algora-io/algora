defmodule Algora.Repo.Migrations.AddVisibilityToBounties do
  use Ecto.Migration

  def change do
    # Set default for bounty_mode in users table
    alter table(:users) do
      modify :bounty_mode, :string, default: "public"
    end

    # Add visibility field to bounties table
    alter table(:bounties) do
      add :visibility, :string, default: "public"
    end

    # Create a check constraint to ensure visibility is one of the allowed values
    create constraint("bounties", :visibility_values,
             check: "visibility IN ('community', 'exclusive', 'public')"
           )
  end
end
