defmodule Algora.Repo.Migrations.AddOriginalUrlToUserMedia do
  use Ecto.Migration

  def change do
    alter table(:user_media) do
      add :original_url, :string
    end
  end
end
