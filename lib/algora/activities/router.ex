defmodule Algora.Activities.Router do
  alias Algora.Accounts.Identity
  alias Algora.Bounties.Bounty

  def route(%{assoc: %Bounty{owner: user}}), do: {:ok, "/#{user.handle}/bounties"}

  def route(%{assoc: %Identity{user: %{type: :individual} = user}}), do: {:ok, "/@/#{user.handle}"}

  def route(%{assoc: %Identity{user: %{type: :organization} = user}}), do: {:ok, "/#{user.handle}"}

  def route(_activity) do
    {:error, :not_found}
  end
end
