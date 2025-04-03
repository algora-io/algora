defmodule Algora.Repo.Migrations.MakeRepositoryNameCitext do
  use Ecto.Migration

  def up do
    alter table(:repositories) do
      modify :name, :citext
    end
  end

  def down do
    alter table(:repositories) do
      modify :name, :string
    end
  end
end
