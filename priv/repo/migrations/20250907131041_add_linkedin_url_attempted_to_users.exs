defmodule Algora.Repo.Migrations.AddLinkedinUrlAttemptedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :linkedin_url_attempted, :boolean, default: false
    end
  end
end
