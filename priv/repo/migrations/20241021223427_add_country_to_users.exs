defmodule Algora.Repo.Migrations.AddCountryToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :country, :string
    end
  end
end
