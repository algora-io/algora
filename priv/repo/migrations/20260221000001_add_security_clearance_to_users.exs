defmodule Algora.Repo.Migrations.AddSecurityClearanceToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :security_clearance, :string
    end
  end
end
