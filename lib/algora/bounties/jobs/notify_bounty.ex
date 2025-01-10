defmodule Algora.Bounties.Jobs.NotifyBounty do
  @moduledoc false
  use Oban.Worker, queue: :notify_bounty

  alias Algora.Github

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"owner_login" => owner_login, "amount" => amount, "ticket_ref" => ticket_ref}}) do
    body = """
    💎 **#{owner_login}** is offering a **#{amount}** bounty for this issue

    👉 Got a pull request resolving this? Claim the bounty by commenting `/claim ##{ticket_ref["number"]}` in your PR and joining swift.algora.io
    """

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
end
