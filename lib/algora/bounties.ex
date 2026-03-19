defmodule Algora.Bounties do
  @moduledoc """
  The Bounties context.
  """

  import Ecto.Query, warn: false
  alias Algora.Repo

  alias Algora.Bounties.Bounty

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
  Gets a single bounty.

  Raises `Ecto.NoResultsError` if the Bounty does not exist.

  ## Examples

      iex> get_bounty!(123)
      %Bounty{}

      iex> get_bounty!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bounty!(id), do: Repo.get!(Bounty, id)

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
  Syncs a bounty's status with its GitHub issue/PR status.

  ## Examples

      iex> sync_bounty_status(bounty)
      {:ok, %Bounty{}}

      iex> sync_bounty_status(bounty)
      {:error, %Ecto.Changeset{}}

  """
  def sync_bounty_status(%Bounty{github_repo: repo, github_issue_number: issue_number} = bounty) 
      when is_binary(repo) and is_integer(issue_number) do
    with {:ok, github_data} <- fetch_github_issue_status(repo, issue_number),
         {:ok, updated_bounty} <- update_bounty_from_github_data(bounty, github_data) do
      {:ok, updated_bounty}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def sync_bounty_status(%Bounty{} = bounty) do
    {:error, "Missing GitHub repository or issue number"}
  end

  defp fetch_github_issue_status(repo, issue_number) do
    url = "https://api.github.com/repos/#{repo}/issues/#{issue_number}"
    headers = [
      {"Accept", "application/vnd.github.v3+json"},
      {"User-Agent", "Algora-App"}
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, _} -> {:error, "Failed to parse GitHub response"}
        end
      
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "GitHub issue not found"}
      
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "GitHub API returned status #{status_code}"}
      
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{reason}"}
    end
  end

  defp update_bounty_from_github_data(bounty, github_data) do
    github_state = Map.get(github_data, "state", "open")
    is_pr = Map.has_key?(github_data, "pull_request")
    
    new_status = determine_bounty_status(github_state, is_pr, github_data)
    
    if bounty.status != new_status do
      update_bounty(bounty, %{status: new_status})
    else
      {:ok, bounty}
    end
  end

  defp determine_bounty_status("closed", true, github_data) do
    # For pull requests, check if it was merged
    case Map.get(github_data, "merged_at") do
      nil -> :completed  # PR closed but not merged
      _ -> :completed    # PR merged
    end
  end

  defp determine_bounty_status("closed", false, _github_data) do
    # For issues, closed means completed
    :completed
  end

  defp determine_bounty_status("open", _, _github_data) do
    :open
  end

  defp determine_bounty_status(_, _, _) do
    :open  # Default fallback
  end
end