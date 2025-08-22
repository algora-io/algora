defmodule Algora.Repo.Migrations.AddPrestigeToExperiences do
  use Ecto.Migration

  def change do
    alter table(:experiences) do
      add :prestige, :integer, default: 2
    end
  end
end
