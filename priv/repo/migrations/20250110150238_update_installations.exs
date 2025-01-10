defmodule Algora.Repo.Migrations.UpdateInstallations do
  use Ecto.Migration

  def up do
    alter table(:installations) do
      modify :owner_id, :string, null: true
      modify :connected_user_id, :string, null: true
      add :provider_user_id, :string, null: false
      remove :provider_login
    end
  end

  def down do
    alter table(:installations) do
      modify :owner_id, :string, null: false
      modify :connected_user_id, :string, null: false
      remove :provider_user_id
      add :provider_login, :string, null: false
    end
  end
end
