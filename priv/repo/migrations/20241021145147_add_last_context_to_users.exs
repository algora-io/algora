defmodule Algora.Repo.Migrations.AddLastContextToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :last_context, :string
    end
  end
end
