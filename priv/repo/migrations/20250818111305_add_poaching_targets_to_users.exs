defmodule Algora.Repo.Migrations.AddPoachingTargetsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :poaching_targets, :text
    end
  end
end