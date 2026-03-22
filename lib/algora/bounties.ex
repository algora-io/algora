defmodule Algora.Bounties do
  @moduledoc """
  The Bounties context.
  """

  import Ecto.Query, warn: false
  alias Algora.Repo

  alias Algora.Bounties.Bounty
  alias Algora.Organizations.Organization

  @doc """
  Returns the list of bounties.

  ## Examples

      iex> list_bounties()
      [%Bounty{}, ...]

  """
  def list_bounties do
    Repo.all(Bounty)
  end

  @doc """
  Returns the list of bounties for an organization.

  ## Examples

      iex> list_org_bounties(org_id)
      [%Bounty{}, ...]

  """
  def list_org_bounties(org_id) do
    from(b in Bounty,
      where: b.org_id == ^org_id,
      order_by: [desc: b.updated_at]
    )
    |> Repo.all()
    |> preload_associations()
  end

  @doc """
  Returns the list of active bounties for an organization.
  Active bounties are those that are open and have claims.

  ## Examples

      iex> list_active_org_bounties(org_id)
      [%Bounty{}, ...]

  """
  def list_active_org_bounties(org_id) do
    from(b in Bounty,
      where: b.org_id == ^org_id and b.status == "open" and b.claims_count > 0,
      order_by: [desc: b.updated_at]
    )
    |> Repo.all()
    |> preload_associations()
  end

  @doc """
  Returns the list of available bounties for an organization.
  Available bounties are those that are open and have no claims.

  ## Examples

      iex> list_available_org_bounties(org_id)
      [%Bounty{}, ...]

  """
  def list_available_org_bounties(org_id) do
    from(b in Bounty,
      where: b.org_id == ^org_id and b.status == "open" and b.claims_count == 0,
      order_by: [desc: b.updated_at]
    )
    |> Repo.all()
    |> preload_associations()
  end

  @doc """
  Returns the list of completed bounties for an organization.

  ## Examples

      iex> list_completed_org_bounties(org_id)
      [%Bounty{}, ...]

  """
  def list_completed_org_bounties(org_id) do
    from(b in Bounty,
      where: b.org_id == ^org_id and b.status == "closed",
      order_by: [desc: b.updated_at]
    )
    |> Repo.all()
    |> preload_associations()
  end

  @doc """
  Gets a single bounty.

  Raises `Ecto.NoResultsError` if the Bounty does not exist.

  ## Examples

      iex> get_bounty!(123)
      %Bounty{}

      iex> get_bounty!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bounty!(id) do
    Repo.get!(Bounty, id)
    |> preload_associations()
  end

  @doc """
  Gets a single bounty by GitHub issue URL.

  ## Examples

      iex> get_bounty_by_github_url("https://github.com/org/repo/issues/123")
      %Bounty{}

      iex> get_bounty_by_github_url("non-existent")
      nil

  """
  def get_bounty_by_github_url(github_url) do
    Repo.get_by(Bounty, github_issue_url: github_url)
    |> case do
      nil -> nil
      bounty -> preload_associations(bounty)
    end
  end

  @doc """
  Creates a bounty.

  ## Examples

      iex> create_bounty(%{field: value})
      {:ok, %Bounty{}}

      iex> create_bounty(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bounty(attrs \\ %{}) do
    %Bounty{}
    |> Bounty.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bounty.

  ## Examples

      iex> update_bounty(bounty, %{field: new_value})
      {:ok, %Bounty{}}

      iex> update_bounty(bounty, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bounty(%Bounty{} = bounty, attrs) do
    bounty
    |> Bounty.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bounty.

  ## Examples

      iex> delete_bounty(bounty)
      {:ok, %Bounty{}}

      iex> delete_bounty(bounty)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bounty(%Bounty{} = bounty) do
    Repo.delete(bounty)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bounty changes.

  ## Examples

      iex> change_bounty(bounty)
      %Ecto.Changeset{data: %Bounty{}}

  """
  def change_bounty(%Bounty{} = bounty, attrs \\ %{}) do
    Bounty.changeset(bounty, attrs)
  end

  @doc """
  Syncs bounty status from GitHub API.
  Updates bounty status and claims count based on GitHub issue state and activity.
  """
  def sync_bounty_from_github(%Bounty{} = bounty) do
    with {:ok, issue_data} <- fetch_github_issue(bounty.github_issue_url),
         {:ok, claims_count} <- count_github_claims(issue_data) do
      
      status = if issue_data["state"] == "closed", do: "closed", else: "open"
      
      update_bounty(bounty, %{
        status: status,
        claims_count: claims_count,
        github_updated_at: parse_github_timestamp(issue_data["updated_at"])
      })
    else
      {:error, reason} ->
        {:error, "Failed to sync bounty #{bounty.id}: #{reason}"}
    end
  end

  @doc """
  Syncs all bounties for an organization from GitHub.
  """
  def sync_org_bounties(org_id) do
    bounties = list_org_bounties(org_id)
    
    results = 
      Enum.map(bounties, fn bounty ->
        case sync_bounty_from_github(bounty) do
          {:ok, updated_bounty} -> {:ok, updated_bounty}
          {:error, reason} -> {:error, {bounty.id, reason}}
        end
      end)
    
    successes = Enum.count(results, &match?({:ok, _}, &1))
    errors = Enum.filter(results, &match?({:error, _}, &1))
    
    {:ok, %{synced: successes, errors: errors}}
  end

  @doc """
  Periodic job to sync all bounties from GitHub.
  This should be called by a background job scheduler.
  """
  def sync_all_bounties do
    # Get all organizations with bounties
    org_ids = 
      from(b in Bounty,
        distinct: true,
        select: b.org_id
      )
      |> Repo.all()
    
    results = 
      Enum.map(org_ids, fn org_id ->
        case sync_org_bounties(org_id) do
          {:ok, stats} -> {:ok, {org_id, stats}}
          {:error, reason} -> {:error, {org_id, reason}}
        end
      end)
    
    total_synced = 
      results
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, {_org_id, %{synced: count}}} -> count end)
      |> Enum.sum()
    
    total_errors = 
      results
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, {_org_id, %{errors: errors}}} -> length(errors) end)
      |> Enum.sum()
    
    org_errors = Enum.filter(results, &match?({:error, _}, &1))
    
    {:ok, %{
      organizations_synced: length(org_ids),
      bounties_synced: total_synced,
      bounty_errors: total_errors,
      organization_errors: length(org_errors)
    }}
  end

  # Private functions

  defp preload_associations(bounty) when is_struct(bounty, Bounty) do
    Repo.preload(bounty, [:organization])
  end

  defp preload_associations(bounties) when is_list(bounties) do
    Repo.preload(bounties, [:organization])
  end

  defp fetch_github_issue(github_url) do
    case extract_github_info(github_url) do
      {:ok, {owner, repo, issue_number}} ->
        url = "https://api.github.com/repos/#{owner}/#{repo}/issues/#{issue_number}"
        
        case HTTPoison.get(url, github_headers()) do
          {:ok, %{status_code: 200, body: body}} ->
            Jason.decode(body)
          {:ok, %{status_code: status_code}} ->
            {:error, "GitHub API returned status #{status_code}"}
          {:error, reason} ->
            {:error, "HTTP request failed: #{inspect(reason)}"}
        end
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_github_info(github_url) do
    case Regex.run(~r/github\.com\/([^\/]+)\/([^\/]+)\/issues\/(\d+)/, github_url) do
      [_, owner, repo, issue_number] ->
        {:ok, {owner, repo, issue_number}}
      nil ->
        {:error, "Invalid GitHub issue URL format"}
    end
  end

  defp count_github_claims(issue_data) do
    # Count comments that indicate claims or work being done
    comments_url = issue_data["comments_url"]
    
    case HTTPoison.get(comments_url, github_headers()) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, comments} ->
            claims_count = 
              comments
              |> Enum.count(fn comment ->
                body = String.downcase(comment["body"] || "")
                String.contains?(body, ["claim", "working on", "assigned to"])
              end)
            
            {:ok, claims_count}
          
          {:error, _} ->
            {:ok, 0}
        end
      
      _ ->
        {:ok, 0}
    end
  end

  defp parse_github_timestamp(timestamp_str) when is_binary(timestamp_str) do
    case DateTime.from_iso8601(timestamp_str) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> DateTime.utc_now()
    end
  end

  defp parse_github_timestamp(_), do: DateTime.utc_now()

  defp github_headers do
    token = Application.get_env(:algora, :github_token)
    
    headers = [
      {"Accept", "application/vnd.github.v3+json"},
      {"User-Agent", "Algora-Bounty-Sync"}
    ]
    
    if token do
      [{"Authorization", "token #{token}"} | headers]
    else
      headers
    end
  end
end