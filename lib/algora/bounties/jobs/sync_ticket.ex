defmodule Algora.Bounties.Jobs.SyncTicket do
  @moduledoc false
  use Oban.Worker,
    queue: :internal,
    max_attempts: 3

  alias Algora.Github
  alias Algora.Workspace

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"owner_login" => owner_login, "repo_name" => repo_name, "number" => number}}) do
    token = Github.TokenPool.get_token()

    case Workspace.update_ticket_from_github(token, owner_login, repo_name, number) do
      {:ok, _ticket} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to sync ticket #{owner_login}/#{repo_name}##{number}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
