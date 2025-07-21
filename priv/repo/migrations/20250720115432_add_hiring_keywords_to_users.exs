defmodule Algora.Repo.Migrations.AddHiringKeywordsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :hiring_keywords, :text
    end
  end
end
