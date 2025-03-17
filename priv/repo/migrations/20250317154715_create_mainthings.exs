defmodule Algora.Repo.Migrations.CreateMainthings do
  use Ecto.Migration

  def change do
    create table(:mainthings) do
      add :content, :text, null: false

      timestamps()
    end
  end
end
