defmodule AlgoraWeb.API.BountyJSON do
  alias Algora.Bounties.Bounty

  @doc """
  Renders a list of bounties.
  """
  def index(%{bounties: bounties}) do
    %{data: for(bounty <- bounties, do: data(bounty))}
  end

  @doc """
  Renders a single bounty.
  """
  def show(%{bounty: bounty}) do
    %{data: data(bounty)}
  end

  defp data(%Bounty{} = bounty) do
    %{
      id: bounty.id,
      amount: bounty.amount,
      status: bounty.status,
      type: "standard",
      kind: "dev",
      reward_type: "cash",
      visibility: bounty.visibility,
      autopay_disabled: bounty.autopay_disabled,
      timeouts_disabled: true,
      manual_assignments: false,
      created_at: bounty.inserted_at,
      updated_at: bounty.updated_at,
      ticket: ticket_data(bounty.ticket),
      owner: user_data(bounty.owner),
      creator: user_data(bounty.creator)
    }
  end

  defp data(%{} = bounty) do
    %{
      id: bounty.id,
      amount: bounty.amount,
      status: bounty.status,
      type: "standard",
      kind: "dev",
      reward_type: "cash",
      visibility: Map.get(bounty, :visibility, :public),
      autopay_disabled: Map.get(bounty, :autopay_disabled, false),
      timeouts_disabled: true,
      manual_assignments: false,
      created_at: bounty.inserted_at,
      updated_at: Map.get(bounty, :updated_at, bounty.inserted_at),
      ticket: ticket_data(bounty.ticket),
      owner: user_data(bounty.owner),
      creator: user_data(Map.get(bounty, :creator))
    }
  end

  defp ticket_data(nil), do: nil

  defp ticket_data(ticket) do
    %{
      id: ticket.id,
      url: ticket.url,
      number: ticket.number,
      # provider: ticket.provider,
      # hash: ticket.hash,
      tech: []
    }
  end

  defp user_data(nil), do: nil

  defp user_data(user) do
    %{
      id: user.id,
      handle: user.handle,
      name: user.name,
      avatar_url: user.avatar_url
    }
  end
end
