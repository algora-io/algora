defmodule Algora.Repo.Migrations.AddGoogleScholarUrlToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :google_scholar_url, :string
    end
  end
end
