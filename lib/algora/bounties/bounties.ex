defmodule Algora.Bounties do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.BotTemplates
  alias Algora.BotTemplates.BotTemplate
  alias Algora.Bounties.Attempt
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Jobs
  alias Algora.Bounties.LineItem
  alias Algora.Bounties.Tip
  alias Algora.Organizations.Member
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.PSP
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Ticket

  require Logger

  def base_query, do: Bounty

  @type criterion ::
          {:id, String.t()}
          | {:limit, non_neg_integer() | :infinity}
          | {:ticket_id, String.t()}
          | {:owner_id, String.t()}
          | {:owner_handles, [String.t()]}
          | {:status, :open | :paid}
          | {:tech_stack, [String.t()]}
          | {:before, %{inserted_at: DateTime.t(), id: String.t()}}
          | {:amount_gt, Money.t()}
          | {:current_user, User.t()}

  def broadcast do
    Phoenix.PubSub.broadcast(Algora.PubSub, "bounties:all", :bounties_updated)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Algora.PubSub, "bounties:all")
  end

  def sync_github_issue_status(%Bounty{} = bounty) do
    with {:ok, installation} <- get_installation_for_bounty(bounty),
         {:ok, access_token} <- get_github_access_token(installation),
         {:ok, issue_data} <- fetch_github_issue(bounty, access_token) do
      
      # Extract issue status and PR count
      is_open = issue_data["state"] == "open"
      pr_count = count_related_pull_requests(issue_data, access_token)
      
      # Update bounty status based on GitHub issue state
      new_status = if is_open, do: :open, else: :paid
      
      # Update bounty with GitHub data
      bounty
      |> change(%{
        status: new_status,
        claims_count: pr_count
      })
      |> Repo.update()
    else
      {:error, reason} ->
        Logger.warning("Failed to sync GitHub issue status for bounty #{bounty.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def sync_all_bounties_github_status do
    bounties_to_sync = 
      Bounty
      |> where([b], b.status == :open)
      |> preload([:ticket])
      |> Repo.all()

    Enum.each(bounties_to_sync, fn bounty ->
      case sync_github_issue_status(bounty) do
        {:ok, _updated_bounty} ->
          Logger.info("Successfully synced bounty #{bounty.id}")
        {:error, reason} ->
          Logger.warning("Failed to sync bounty #{bounty.id}: #{inspect(reason)}")
      end
    end)

    broadcast()
  end

  defp get_installation_for_bounty(%Bounty{ticket: %Ticket{} = ticket}) do
    installation = 
      Installation
      |> where([i], i.owner == ^ticket.owner and i.repo == ^ticket.repo)
      |> Repo.one()

    case installation do
      nil -> {:error, :installation_not_found}
      installation -> {:ok, installation}
    end
  end

  defp get_github_access_token(%Installation{} = installation) do
    case Workspace.get_github_access_token(installation) do
      {:ok, token} -> {:ok, token}
      error -> error
    end
  end

  defp fetch_github_issue(%Bounty{ticket: %Ticket{} = ticket}, access_token) do
    url = "https://api.github.com/repos/#{ticket.owner}/#{ticket.repo}/issues/#{ticket.number}"
    headers = [
      {"Authorization", "token #{access_token}"},
      {"Accept", "application/vnd.github.v3+json"},
      {"User-Agent", "Algora-Bounties"}
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, _} -> {:error, :json_decode_error}
        end
      {:ok, %{status_code: status_code}} ->
        {:error, {:github_api_error, status_code}}
      {:error, reason} ->
        {:error, {:http_error, reason}}
    end
  end

  defp count_related_pull_requests(issue_data, access_token) do
    # Get pull requests that reference this issue
    repo_url = issue_data["repository_url"]
    issue_number = issue_data["number"]
    
    prs_url = "#{repo_url}/pulls?state=all"
    headers = [
      {"Authorization", "token #{access_token}"},
      {"Accept", "application/vnd.github.v3+json"},
      {"User-Agent", "Algora-Bounties"}
    ]

    case HTTPoison.get(prs_url, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, prs} ->
            # Count PRs that mention this issue in title or body
            prs
            |> Enum.count(fn pr ->
              title = pr["title"] || ""
              body = pr["body"] || ""
              
              String.contains?(title, "##{issue_number}") or
              String.contains?(body, "##{issue_number}") or
              String.contains?(body, "closes ##{issue_number}") or
              String.contains?(body, "fixes ##{issue_number}")
            end)
          {:error, _} -> 0
        end
      _ -> 0
    end
  end

  @spec do_create_bounty(%{
          creator: User.t(),
          owner: User.t(),
          amount: Money.t(),
          ticket: Ticket.t(),
          visibility: Bounty.visibility(),
          sharing_percentage: non_neg_integer()
        }) :: {:ok, Bounty.t()} | {:error, Ecto.Changeset.t()}