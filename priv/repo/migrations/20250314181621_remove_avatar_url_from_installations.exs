defmodule Algora.Repo.Migrations.RemoveAvatarUrlFromInstallations do
  use Ecto.Migration

  def change do
    alter table(:installations) do
      remove :avatar_url
    end
  end
end
