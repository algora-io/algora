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

  def get_top_reviews_for_users(user_ids) when is_list(user_ids) do
    # First, get the latest highest-rated review for each user
    latest_reviews_query =
      from r in Review,
        where: r.reviewee_id in ^user_ids,
        join: rr in assoc(r, :reviewer),
        join: o in assoc(r, :organization),
        # Get the review with highest rating for each reviewee
        distinct: r.reviewee_id,
        order_by: [desc: r.rating, desc: r.inserted_at],
        select: %{
          reviewee_id: r.reviewee_id,
          rating: r.rating,
          content: r.content,
          reviewer: %{
            display_name: rr.display_name,
            avatar_url: rr.avatar_url
          },
          organization: %{
            display_name: o.display_name
          }
        }

    # Execute query and convert to map with reviewee_id as key
    Repo.all(latest_reviews_query)
    |> Map.new(fn review -> {review.reviewee_id, review} end)
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
