defmodule Algora.Repo.Migrations.UpdateUserCategories do
  use Ecto.Migration

  def change do
    execute "UPDATE users SET categories = '{}' WHERE categories IS NULL"

    alter table(:users) do
      modify :categories, {:array, :string}, null: false, default: "{}"
    end
  end
end
