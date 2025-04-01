defmodule Algora.Repo.Migrations.AddDeadlineToBounties do
  use Ecto.Migration

  def change do
    alter table(:bounties) do
      add :deadline, :utc_datetime_usec
    end
  end
end
