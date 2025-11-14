defmodule Algora.Repo.Migrations.AddProgressToLeads do
  use Ecto.Migration

  def change do
    alter table(:leads) do
      add :progress, :string
    end
  end
end
