defmodule Algora.Repo.Migrations.AddDmThreadUrlToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :dm_thread_url, :string
    end
  end
end
