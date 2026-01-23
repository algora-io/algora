defmodule Algora.Repo.Migrations.AddDomainIndexToUsers do
  use Ecto.Migration

  def change do
    create index(:users, [:domain])
  end
end
