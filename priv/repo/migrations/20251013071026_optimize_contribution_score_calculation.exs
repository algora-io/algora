defmodule Algora.Repo.Migrations.OptimizeContributionScoreCalculation do
  use Ecto.Migration

  def change do
    create_if_not_exists index(
                           :user_contributions,
                           [:user_id, :contribution_count, :repository_id],
                           name: :idx_user_contributions_score_calc
                         )

    create_if_not_exists index(:repositories, [:id, :tech_stack, :topics, :stargazers_count],
                           name: :idx_repositories_score_calc
                         )
  end
end
