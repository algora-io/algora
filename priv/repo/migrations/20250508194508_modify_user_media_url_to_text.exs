defmodule Algora.Repo.Migrations.ModifyUserMediaUrlToText do
  use Ecto.Migration

  def change do
    alter table(:user_media) do
      modify :url, :text, null: false
    end
  end
end
