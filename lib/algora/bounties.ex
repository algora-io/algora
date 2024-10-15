defmodule Algora.Bounties do
  import Ecto.Query

  alias Algora.Bounties.Bounty
  alias Algora.Repo
  alias Algora.Accounts
  alias Algora.Work

  def create_bounty(creator, owner, url, amount) do
    with {:ok, token} <- Accounts.get_access_token(creator),
         {:ok, %{"owner" => owner, "repo" => repo, "number" => number}} <- parse_url(url),
         {:ok, task} <-
           Work.fetch_task(:github, %{token: token, owner: owner, repo: repo, number: number}) do
      %Bounty{}
      |> Bounty.changeset(%{
        amount: Decimal.new(amount),
        currency: "USD",
        task_id: task.id,
        user_id: owner.id
      })
      |> Repo.insert()
    else
      error -> error
    end
  end

  @spec list_bounties(
          params :: %{optional(:user_id) => integer(), optional(:limit) => non_neg_integer()}
        ) :: [map()]
  def list_bounties(params) do
    limit = params[:limit] || 10

    query =
      from b in Bounty,
        join: t in assoc(b, :task),
        join: r in assoc(t, :repository),
        join: u in assoc(r, :user),
        select: %{
          id: b.id,
          inserted_at: b.inserted_at,
          amount: b.amount,
          currency: b.currency,
          task: %{
            title: t.title,
            owner: u.provider_login,
            repo: r.name,
            number: t.number
          }
        },
        limit: ^limit

    query
    |> maybe_filter_by_user_id(params[:user_id])
    |> Repo.all()
  end

  defp maybe_filter_by_user_id(query, nil), do: query

  defp maybe_filter_by_user_id(query, user_id) do
    from [b, t] in query,
      where: b.user_id == ^user_id
  end

  defp parse_url(url) do
    cond do
      issue_params = parse_url(:github, :issue, url) ->
        {:ok, issue_params |> Map.put("type", :issue)}

      pr_params = parse_url(:github, :pull_request, url) ->
        {:ok, pr_params |> Map.put("type", :pull_request)}

      true ->
        :error
    end
  end

  defp parse_url(:github, :issue, url) do
    regex =
      ~r|https?://(?:www\.)?github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/issues/(?<number>\d+)|

    parse_with_regex(regex, url)
  end

  defp parse_url(:github, :pull_request, url) do
    regex =
      ~r|https?://(?:www\.)?github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/pull/(?<number>\d+)|

    parse_with_regex(regex, url)
  end

  defp parse_with_regex(regex, url) do
    case Regex.named_captures(regex, url) do
      %{"owner" => owner, "repo" => repo, "number" => number} ->
        %{"owner" => owner, "repo" => repo, "number" => String.to_integer(number)}

      nil ->
        nil
    end
  end
end
