defmodule AlgoraWeb.API.BountyController do
  use AlgoraWeb, :controller

  alias Algora.Bounties
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
end
