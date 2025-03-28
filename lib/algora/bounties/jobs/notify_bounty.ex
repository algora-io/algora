defmodule Algora.Bounties.Jobs.NotifyBounty do
  @moduledoc false
  use Oban.Worker,
    queue: :notify_bounty,
    max_attempts: 1

  alias Algora.Bounties
  alias Algora.Github
  alias Algora.Workspace

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"bounty_id" => bounty_id, "visibility" => "exclusive", "shared_with" => shared_with}}) do
    Algora.Admin.alert("Notify exclusive bounty #{bounty_id} to #{inspect(shared_with)}")
  end

  def perform(%Oban.Job{
        args: %{
          "owner_login" => owner_login,
          "amount" => amount,
          "ticket_ref" => ticket_ref,
          "installation_id" => nil,
          "command_id" => command_id,
          "command_source" => command_source
        }
      }) do
    ticket_ref = %{
      owner: ticket_ref["owner"],
      repo: ticket_ref["repo"],
      number: ticket_ref["number"]
    }

    body = """
    💎 **#{owner_login}** is offering a **#{amount}** bounty for this issue

    👉 Got a pull request resolving this? Claim the bounty by commenting `/claim ##{ticket_ref.number}` in your PR and joining #{AlgoraWeb.Endpoint.host()}
    """

    if Github.pat_enabled() do
      with {:ok, ticket} <-
             Workspace.ensure_ticket(
               Github.pat(),
               ticket_ref.owner,
               ticket_ref.repo,
               ticket_ref.number
             ) do
        Workspace.ensure_command_response(%{
          token: Github.pat(),
          ticket_ref: ticket_ref,
          command_id: command_id,
          command_type: :bounty,
          command_source: command_source,
          ticket: ticket,
          body: body
        })
      end
    else
      Logger.info("""
      Github.create_issue_comment(Github.pat(), "#{ticket_ref.owner}", "#{ticket_ref.repo}", #{ticket_ref.number},
             \"\"\"
             #{body}
             \"\"\")
      """)
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "amount" => _amount,
          "ticket_ref" => ticket_ref,
          "installation_id" => installation_id,
          "command_id" => command_id,
          "command_source" => command_source
        }
      }) do
    ticket_ref = %{
      owner: ticket_ref["owner"],
      repo: ticket_ref["repo"],
      number: ticket_ref["number"]
    }

    with {:ok, token} <- Github.get_installation_token(installation_id),
         {:ok, ticket} <-
           Workspace.ensure_ticket(token, ticket_ref.owner, ticket_ref.repo, ticket_ref.number),
         {:ok, bounties} <- Bounties.list_bounties(ticket_id: ticket.id),
         true <- bounties != [],
         {:ok, _} <-
           Github.add_labels(token, ticket_ref.owner, ticket_ref.repo, ticket_ref.number, [
             "💎 Bounty"
           ]) do
      attempts = Bounties.list_attempts_for_ticket(ticket.id)
      claims = Bounties.list_claims([ticket.id])

      Workspace.ensure_command_response(%{
        token: token,
        ticket_ref: ticket_ref,
        command_id: command_id,
        command_type: :bounty,
        command_source: command_source,
        ticket: ticket,
        body: Bounties.get_response_body(bounties, ticket_ref, attempts, claims)
      })
    end
  end
end
