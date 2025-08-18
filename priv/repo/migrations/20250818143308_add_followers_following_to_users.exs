defmodule Algora.Repo.Migrations.AddFollowersFollowingToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :followers_count, :integer, default: 0
      add :following_count, :integer, default: 0
    end
  end
end
