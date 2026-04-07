defmodule Algora.Bounties.Jobs.SyncOpenBounties do
  @moduledoc false
  use Oban.Worker,
    queue: :internal,
    max_attempts: 3

  alias Algora.Bounties
  alias Algora.Bounties.Jobs.SyncTicket

  @page_size 100

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    enqueue_page(nil)
  end

  defp enqueue_page(cursor) do
    criteria = [status: :open, limit: @page_size] ++ if(cursor, do: [before: cursor], else: [])
    bounties = Bounties.list_bounties(criteria)

    jobs =
      Enum.map(bounties, fn bounty ->
        SyncTicket.new(%{
          owner_login: bounty.repository.owner.provider_login,
          repo_name: bounty.repository.name,
          number: bounty.ticket.number
        })
      end)

    Oban.insert_all(jobs)

    if length(bounties) == @page_size do
      last = List.last(bounties)
      enqueue_page(%{inserted_at: last.inserted_at, id: last.id})
    else
      :ok
    end
  end
end
