defmodule Algora.Bounties.Jobs.NotifyTipIntent do
  @moduledoc false
  use Oban.Worker, queue: :notify_tip_intent

  alias Algora.Github

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"body" => body, "ticket_ref" => ticket_ref, "installation_id" => nil}}) do
    Github.try_without_installation(&Github.create_issue_comment/5, [
      ticket_ref["owner"],
      ticket_ref["repo"],
      ticket_ref["number"],
      body
    ])
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"body" => body, "ticket_ref" => ticket_ref, "installation_id" => installation_id}}) do
    with {:ok, token} <- Github.get_installation_token(installation_id) do
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
