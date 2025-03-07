defmodule Algora.Repo.Migrations.AddCompanyTypesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :categories, {:array, :string}, default: []
    end
  end
end
