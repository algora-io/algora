defmodule Algora.Reviews do
  alias Algora.Repo
  alias Algora.Reviews.Review

  def create_review(attrs) do
    %Review{}
    |> Review.changeset(attrs)
    |> Repo.insert()
  end
end
