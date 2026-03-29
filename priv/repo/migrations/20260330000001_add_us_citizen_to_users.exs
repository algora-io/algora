defmodule Algora.Repo.Migrations.AddUsCitizenToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :us_citizen, :boolean
    end
  end
end
