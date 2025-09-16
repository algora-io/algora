defmodule Algora.Repo.Migrations.AddIndexToUsersStage do
  use Ecto.Migration

  def change do
    create index(:users, [:stage])
  end
end
