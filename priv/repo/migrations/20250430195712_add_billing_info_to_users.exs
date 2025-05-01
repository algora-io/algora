defmodule Algora.Repo.Migrations.AddBillingInfoToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :billing_name, :string
      add :billing_address, :string
      add :executive_name, :string
      add :executive_role, :string
    end

    # Set billing_name for existing users
    execute """
    UPDATE users
    SET billing_name = COALESCE(display_name, handle)
    WHERE billing_name IS NULL
    """
  end
end
