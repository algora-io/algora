defmodule Algora.Repo.Migrations.AddReadmeContentToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :readme, :text
    end
  end
end
