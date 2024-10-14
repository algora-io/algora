defmodule Algora.Repo.Migrations.AddFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :handle, :string, null: true
    end
  end
end
