defmodule Algora.Repo.Migrations.DropExternalHomepageUrlFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :external_homepage_url
    end
  end
end
