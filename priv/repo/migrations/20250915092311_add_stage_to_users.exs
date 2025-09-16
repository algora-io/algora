defmodule Algora.Repo.Migrations.AddStageToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stage, :string, null: true
    end
  end
end
