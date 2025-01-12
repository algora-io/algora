defmodule Algora.Bounties.Jobs.NotifyClaim do
  @moduledoc false
  use Oban.Worker, queue: :notify_claim

  alias Algora.Github

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"ticket_ref" => _ticket_ref, "installation_id" => nil}}) do
    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"ticket_ref" => ticket_ref, "installation_id" => installation_id}}) do
    with {:ok, token} <- Github.get_installation_token(installation_id) do
      body = "Claimed!"

      Github.create_issue_comment(
        token,
        ticket_ref["owner"],
        ticket_ref["repo"],
        ticket_ref["number"],
        body
      )
    end
  end
end
