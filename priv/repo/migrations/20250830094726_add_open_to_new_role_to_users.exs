defmodule Algora.Repo.Migrations.AddOpenToNewRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :open_to_new_role, :boolean, default: true
    end
  end
end
