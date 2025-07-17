defmodule AlgoraWeb.API.ProfileController do
  use AlgoraWeb, :controller

  alias Algora.Accounts
  alias Algora.Payments
  alias Algora.Reviews
  alias Algora.Workspace

  def show(conn, %{"user_handle" => handle} = params) do
    limit = parse_limit(params["limit"])

    with {:ok, user} <- Accounts.fetch_developer_by(handle: handle) do
      transactions = Payments.list_received_transactions(user.id, limit: limit)
      enriched_transactions = enrich_transactions(transactions)
      reviews = Reviews.list_reviews(reviewee_id: user.id, limit: limit)
      contributions = Workspace.list_user_contributions([user.id], limit: limit, display_all: true)

      json(conn, %{
        id: user.id,
        name: user.name,
        handle: user.handle,
        bio: user.bio,

        contributions: Enum.map(contributions, &contribution_to_json/1),
        total_stars: total_stars(contributions),
        total_contributions: total_contributions(contributions),

        transactions: Enum.map(enriched_transactions, &transaction_to_json/1),
        reviews: Enum.map(reviews, &review_to_json/1)
      })
    else
      _ ->
        send_resp(conn, 404, Jason.encode!(%{error: "User not found"}))
    end
  end

  defp parse_limit(limit) when is_binary(limit) do
    case Integer.parse(limit) do
      {num, _} when num > 0 and num <= 100 -> num
      _ -> 10
    end
  end

  defp parse_limit(_), do: 10

  defp enrich_transactions(transactions) do
    Enum.map(transactions, fn tx ->
      project =
        case tx.ticket.repository do
          nil -> tx.sender
          repo -> repo.user
        end

      Map.put(tx, :project, project)
    end)
  end

  defp transaction_to_json(tx) do
    %{
      id: tx.id,
      amount: tx.amount,
      succeeded_at: tx.succeeded_at,
      sender: tx.sender,
      project: tx.project
    }
  end

  defp review_to_json(review) do
    %{
      id: review.id,
      reviewer_id: review.reviewer_id,
      body: review.body,
      inserted_at: review.inserted_at
    }
  end

  defp contribution_to_json(contribution) do
    %{
      repository: %{
        id: contribution.repository.id,
        name: contribution.repository.name,
        stargazers_count: contribution.repository.stargazers_count,
        user: contribution.repository.user
      },
      contribution_count: contribution.contribution_count
    }
  end

  defp total_stars(contributions) do
    contributions
    |> Enum.map(& &1.repository.stargazers_count)
    |> Enum.sum()
  end

  defp total_contributions(contributions) do
    contributions
    |> Enum.map(& &1.contribution_count)
    |> Enum.sum()
  end
end
