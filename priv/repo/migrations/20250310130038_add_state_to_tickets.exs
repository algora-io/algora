defmodule Algora.Repo.Migrations.AddStateToTickets do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
      add :state, :string, default: "open"
      add :closed_at, :utc_datetime_usec
      add :merged_at, :utc_datetime_usec
    end
  end
end
