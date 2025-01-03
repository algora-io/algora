defmodule Algora.Reviews do
  @moduledoc false
  import Ecto.Query

  alias Algora.Repo
  alias Algora.Reviews.Review

  def create_review(attrs) do
    %Review{}
    |> Review.changeset(attrs)
    |> Repo.insert()
  end

  def base_query, do: Review

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

  def list_reviews_with(base_query, criteria \\ []) do
    base_reviews =
      base_query
      |> apply_criteria(criteria)
      |> select([r], r.id)

    from(r in Review)
    |> join(:inner, [r], rr in subquery(base_reviews), on: r.id == rr.id)
    |> join(:inner, [r], o in assoc(r, :organization), as: :o)
    |> join(:inner, [r], rr in assoc(r, :reviewer), as: :rr)
    |> join(:inner, [r], re in assoc(r, :reviewee), as: :re)
    |> select([r, o: o, rr: rr, re: re], %{
      id: r.id,
      inserted_at: r.inserted_at,
      rating: r.rating,
      content: r.content,
      organization: %{
        id: o.id,
        handle: o.handle,
        name: o.name,
        avatar_url: o.avatar_url
      },
      reviewer: %{
        id: rr.id,
        handle: rr.handle,
        name: rr.name,
        avatar_url: rr.avatar_url
      },
      reviewee: %{
        id: re.id,
        handle: re.handle,
        name: re.name,
        avatar_url: re.avatar_url
      }
    })
    |> Repo.all()
  end

  def list_reviews(criteria \\ []) do
    list_reviews_with(base_query(), criteria)
  end

  def get_top_reviews_for_users(user_ids) when is_list(user_ids) do
    base_query()
    |> where([r], r.reviewee_id in ^user_ids)
    |> distinct([r], r.reviewee_id)
    |> order_by([r], desc: r.rating, desc: r.inserted_at)
    |> list_reviews_with()
    |> Map.new(fn review -> {review.reviewee.id, review} end)
  end
end
