defmodule Algora.Bounties.Jobs.NotifyTipIntent do
  @moduledoc false
  use Oban.Worker, queue: :notify_tip_intent

  alias Algora.Github

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"url" => url, "ticket_ref" => ticket_ref, "installation_id" => nil}}) do
    body = get_body(url)

    if Github.pat_enabled() do
      Github.create_issue_comment(
        Github.pat(),
        ticket_ref["owner"],
        ticket_ref["repo"],
        ticket_ref["number"],
        body
      )
    else
      Logger.info("""
      Github.create_issue_comment(Github.pat(), "#{ticket_ref["owner"]}", "#{ticket_ref["repo"]}", #{ticket_ref["number"]},
             \"\"\"
             #{body}
             \"\"\")
      """)
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"url" => url, "ticket_ref" => ticket_ref, "installation_id" => installation_id}}) do
    with {:ok, token} <- Github.get_installation_token(installation_id) do
      body = get_body(url)

      Github.create_issue_comment(
        token,
        ticket_ref["owner"],
        ticket_ref["repo"],
        ticket_ref["number"],
        body
      )
    end
  end

  defp get_body(url), do: "Please visit [Algora](#{url}) to complete your tip via Stripe."
end
