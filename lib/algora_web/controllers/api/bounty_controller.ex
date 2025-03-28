defmodule AlgoraWeb.API.BountyController do
  use AlgoraWeb, :controller

  alias Algora.Bounties
  alias AlgoraWeb.API.FallbackController

  action_fallback FallbackController

  @doc """
  Get a list of bounties with optional filtering parameters.

  Query Parameters:
  - status: string (optional) - Filter by status (open, paid)
  - org: string (optional) - Filter by organization handle
  - limit: integer (optional) - Limit the number of bounties returned
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
    params
    |> Enum.map(&parse_params/1)
    |> Enum.reject(&is_nil/1)
    |> Keyword.new()
  end

  defp to_criteria(_), do: []

  defp parse_params({"status", status}) do
    {:status, parse_status(status)}
  end

  defp parse_params({"org", org_handle}) do
    {:owner_handle, org_handle}
  end

  defp parse_params({"limit", limit}) do
    {:limit, limit}
  end

  defp parse_params(_), do: nil

  # Parse status string to corresponding enum atom
  defp parse_status(status) when is_binary(status) do
    case String.downcase(status) do
      "paid" -> :paid
      _ -> :open
    end
  end

  defp parse_status(_), do: :open
end
