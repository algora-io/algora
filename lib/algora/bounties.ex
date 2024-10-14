defmodule Algora.Bounties do
  alias Algora.Bounties.Bounty
  alias Algora.Repo

  def create_bounty(attrs \\ %{}) do
    %Bounty{}
    |> Bounty.changeset(attrs)
    |> Repo.insert()
  end
end
