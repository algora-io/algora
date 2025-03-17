defmodule Algora.Repo.Migrations.MakeContractDatesNullable do
  use Ecto.Migration

  def change do
    alter table(:contracts) do
      modify :start_date, :utc_datetime_usec, null: true
    end
  end
end
