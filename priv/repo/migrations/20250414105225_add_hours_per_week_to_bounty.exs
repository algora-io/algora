defmodule Algora.Repo.Migrations.AddHoursPerWeekToBounty do
  use Ecto.Migration

  def change do
    alter table(:bounties) do
      add :hours_per_week, :integer
    end
  end
end
