defmodule Algora.Reviews do
  import Ecto.Query
  alias Algora.Repo
  alias Algora.Reviews.Review

  def create_review(attrs) do
    %Review{}
    |> Review.changeset(attrs)
    |> Repo.insert()
  end

  def list_reviews(criteria \\ []) do
    from(r in Review)
    |> join(:inner, [r], o in assoc(r, :organization), as: :o)
    |> join(:inner, [r], rr in assoc(r, :reviewer), as: :rr)
    |> join(:inner, [r], re in assoc(r, :reviewee), as: :re)
    |> apply_criteria(criteria)
    |> preload([o: o, rr: rr, re: re], organization: o, reviewer: rr, reviewee: re)
    |> Repo.all()
  end

  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:id, id}, query ->
        from([r] in query, where: r.id == ^id)

      {:reviewee_id, reviewee_id}, query ->
        from([r] in query, where: r.reviewee_id == ^reviewee_id)

      {:limit, limit}, query ->
        from([r] in query, limit: ^limit)

      _, query ->
        query
    end)
  end
end
