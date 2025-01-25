defmodule Algora.Bounties.Jobs.NotifyBounty do
  @moduledoc false
  use Oban.Worker,
    queue: :notify_bounty,
    max_attempts: 1

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Github
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace
  alias Algora.Workspace.CommandResponse

  require Logger

  @impl Oban.Worker
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
    body = """
    💎 **#{owner_login}** is offering a **#{amount}** bounty for this issue

    👉 Got a pull request resolving this? Claim the bounty by commenting `/claim ##{ticket_ref["number"]}` in your PR and joining swift.algora.io
    """

    if Github.pat_enabled() do
      with {:ok, response} <-
             Github.create_issue_comment(
               Github.pat(),
               ticket_ref["owner"],
               ticket_ref["repo"],
               ticket_ref["number"],
               body
             ),
           {:ok, ticket} <-
             Workspace.ensure_ticket(Github.pat(), ticket_ref["owner"], ticket_ref["repo"], ticket_ref["number"]) do
        %CommandResponse{}
        |> CommandResponse.changeset(%{
          provider: "github",
          provider_meta: Util.normalize_struct(response),
          provider_command_id: to_string(command_id),
          provider_response_id: to_string(response["id"]),
          command_source: command_source,
          command_type: :bounty,
          ticket_id: ticket.id
        })
        |> Repo.insert()
      end
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
  def perform(%Oban.Job{
        args: %{
          "amount" => amount,
          "ticket_ref" => ticket_ref,
          "installation_id" => installation_id,
          "command_id" => command_id,
          "command_source" => command_source
        }
      }) do
    with {:ok, token} <- Github.get_installation_token(installation_id),
         {:ok, installation} <-
           Workspace.fetch_installation_by(provider: "github", provider_id: to_string(installation_id)),
         {:ok, owner} <- Accounts.fetch_user_by(id: installation.connected_user_id),
         {:ok, _} <-
           Github.add_labels(token, ticket_ref["owner"], ticket_ref["repo"], ticket_ref["number"], ["💎 Bounty"]),
         {:ok, ticket} <- Workspace.ensure_ticket(token, ticket_ref["owner"], ticket_ref["repo"], ticket_ref["number"]) do
      body = """
      ## 💎 #{amount} bounty [• #{owner.name}](#{User.url(owner)})
      ### Steps to solve:
      1. **Start working**: Comment `/attempt ##{ticket_ref["number"]}` with your implementation plan
      2. **Submit work**: Create a pull request including `/claim ##{ticket_ref["number"]}` in the PR body to claim the bounty
      3. **Receive payment**: 100% of the bounty is received 2-5 days post-reward. [Make sure you are eligible for payouts](https://docs.algora.io/bounties/payments#supported-countries-regions)

      Thank you for contributing to #{ticket_ref["owner"]}/#{ticket_ref["repo"]}!
      """

      with {:ok, response} <-
             Github.create_issue_comment(
               token,
               ticket_ref["owner"],
               ticket_ref["repo"],
               ticket_ref["number"],
               body
             ) do
        %CommandResponse{}
        |> CommandResponse.changeset(%{
          provider: "github",
          provider_meta: Util.normalize_struct(response),
          provider_command_id: to_string(command_id),
          provider_response_id: to_string(response["id"]),
          command_source: command_source,
          command_type: :bounty,
          ticket_id: ticket.id
        })
        |> Repo.insert()
      end
    end
  end
end
