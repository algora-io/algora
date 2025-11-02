defmodule Algora.Repo.Migrations.AddAshbyFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :ashby_api_key, :string
      add :ashby_source_id, :string
      add :ashby_user_id, :string
    end
  end
end
