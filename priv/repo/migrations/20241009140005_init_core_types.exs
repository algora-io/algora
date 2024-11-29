defmodule Algora.Repo.Migrations.InitCoreTypes do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""
  end
end
