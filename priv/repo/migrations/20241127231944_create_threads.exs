defmodule Algora.Repo.Migrations.CreateThreads do
  use Ecto.Migration

  def change do
    create table(:threads) do
      add :title, :string

      timestamps()
    end
  end
end
