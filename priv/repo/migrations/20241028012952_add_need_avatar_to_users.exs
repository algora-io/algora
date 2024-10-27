defmodule Algora.Repo.Migrations.AddNeedAvatarToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :need_avatar, :boolean, default: false
    end
  end
end
