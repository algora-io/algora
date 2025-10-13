defmodule Algora.Repo.Migrations.AddContributionScoresToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :contribution_scores, :map, default: %{}
    end

    create index(:users, [:contribution_scores],
             using: :gin,
             name: :idx_users_contribution_scores_gin
           )
  end
end
