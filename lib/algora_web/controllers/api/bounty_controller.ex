defmodule AlgoraWeb.API.BountyController do
  use AlgoraWeb, :controller

  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias AlgoraWeb.API.FallbackController

  action_fallback FallbackController

  @doc """
  Get a list of bounties with optional filtering parameters.

  Query Parameters:
  - type: string (optional) - Filter by bounty type (e.g., "standard")
  - kind: string (optional) - Filter by bounty kind (e.g., "dev")
  - reward_type: string (optional) - Filter by reward type (e.g., "cash")
  - visibility: string (optional) - Filter by visibility (e.g., "public")
  - status: string (optional) - Filter by status (open, cancelled, paid)
  """
  def index(conn, %{"batch" => _batch, "input" => input} = _params) do
    with {:ok, decoded} <- Jason.decode(input),
         %{"0" => %{"json" => json}} <- decoded do
      criteria = to_criteria(json)
      bounties = Bounties.list_bounties(criteria)
      render(conn, :index, bounties: bounties)
    end
  end

  def index(conn, params) do
    criteria = to_criteria(params)
    bounties = Bounties.list_bounties(criteria)
    render(conn, :index, bounties: bounties)
  end

  # Convert JSON/map parameters to keyword list criteria
  defp to_criteria(params) when is_map(params) do
    Keyword.new(params, fn
      {"status", status} -> {:status, parse_status(status)}
      {"visibility", visibility} -> {:visibility, parse_visibility(visibility)}
      {"org", org_handle} -> {:owner_handle, org_handle}
      {k, v} -> {String.to_existing_atom(k), v}
    end)
  rescue
    _ -> []
  end

  defp to_criteria(_), do: []

  # Parse status string to corresponding enum atom
  defp parse_status(status) when is_binary(status) do
    case String.downcase(status) do
      "active" -> :open
      "open" -> :open
      "cancelled" -> :cancelled
      "canceled" -> :cancelled
      "paid" -> :paid
      _ -> :open
    end
  end

  defp parse_status(_), do: :open

  # Parse visibility string to corresponding enum atom
  defp parse_visibility(visibility) when is_binary(visibility) do
    case String.downcase(visibility) do
      "public" -> :public
      "community" -> :community
      "exclusive" -> :exclusive
      _ -> :public
    end
  end

  defp parse_visibility(_), do: :public

  @doc """
  Get a specific bounty by ID.
  """
  def show(conn, %{"id" => id}) do
    with {:ok, bounty} <- Bounties.get_bounty(id) do
      render(conn, :show, bounty: bounty)
    end
  end

  @doc """
  Create a new bounty.

  Required Parameters:
  - amount: integer - Bounty amount in cents
  - ticket_id: string - Associated ticket ID
  - type: string - Bounty type (e.g., "standard")
  - kind: string - Bounty kind (e.g., "dev")
  - reward_type: string - Type of reward (e.g., "cash")
  - visibility: string - Visibility setting (e.g., "public")
  """
  def create(conn, params) do
    with {:ok, %Bounty{} = bounty} <- Bounties.create_bounty(params) do
      conn
      |> put_status(:created)
      |> render(:show, bounty: bounty)
    end
  end

  @doc """
  Update an existing bounty.
  """
  def update(conn, %{"id" => id} = params) do
    with {:ok, bounty} <- Bounties.get_bounty(id),
         {:ok, updated_bounty} <- Bounties.update_bounty(bounty, params) do
      render(conn, :show, bounty: updated_bounty)
    end
  end

  @doc """
  Delete a bounty.
  """
  def delete(conn, %{"id" => id}) do
    with {:ok, bounty} <- Bounties.get_bounty(id),
         {:ok, _deleted} <- Bounties.delete_bounty(bounty) do
      send_resp(conn, :no_content, "")
    end
  end
end
