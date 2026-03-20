defmodule Algora.Bounties.Jobs.SyncBountyTicketsTest do
  use Algora.DataCase
  use Oban.Testing, repo: Algora.Repo

  import Algora.Factory

  alias Algora.Bounties.Jobs.SyncBountyTickets

  test "enqueues a sync job for an org" do
    owner = insert!(:user)

    assert {:ok, _} =
             SyncBountyTickets.new(%{"owner_id" => owner.id})
             |> Oban.insert()

    assert_enqueued(worker: SyncBountyTickets, args: %{"owner_id" => owner.id})
  end
end
