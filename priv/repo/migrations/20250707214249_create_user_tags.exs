defmodule Algora.Repo.Migrations.CreateUserTags do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :system_tags, {:array, :string}, default: []
    end
  end
end
