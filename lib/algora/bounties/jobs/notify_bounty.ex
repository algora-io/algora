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
        # TODO: update existing command response if it exists
        create_command_response(response, command_source, command_id, ticket.id)
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

      ensure_command_response(token, ticket_ref, command_id, command_source, ticket, body)
    end
  end

  defp ensure_command_response(token, ticket_ref, command_id, command_source, ticket, body) do
    case Workspace.fetch_command_response(ticket.id, :bounty) do
      {:ok, response} ->
        case Github.update_issue_comment(
               token,
               ticket_ref["owner"],
               ticket_ref["repo"],
               response.provider_response_id,
               body
             ) do
          {:ok, _comment} ->
            try_update_command_response(response, body)

          {:error, "404 Not Found"} ->
            with {:ok, _} <- Workspace.delete_command_response(response.id) do
              post_response(token, ticket_ref, command_id, command_source, ticket, body)
            end

          {:error, reason} ->
            Logger.error("Failed to update command response #{response.id} with body #{body}")
            {:error, reason}
        end

      {:error, _reason} ->
        post_response(token, ticket_ref, command_id, command_source, ticket, body)
    end
  end

  defp post_response(token, ticket_ref, command_id, command_source, ticket, body) do
    with {:ok, comment} <-
           Github.create_issue_comment(token, ticket_ref["owner"], ticket_ref["repo"], ticket_ref["number"], body) do
      create_command_response(comment, command_source, command_id, ticket.id)
    end
  end

  defp create_command_response(comment, command_source, command_id, ticket_id) do
    %CommandResponse{}
    |> CommandResponse.changeset(%{
      provider: "github",
      provider_meta: Util.normalize_struct(comment),
      provider_command_id: to_string(command_id),
      provider_response_id: to_string(comment["id"]),
      command_source: command_source,
      command_type: :bounty,
      ticket_id: ticket_id
    })
    |> Repo.insert()
  end

  defp try_update_command_response(command_response, body) do
    case command_response
         |> CommandResponse.changeset(%{provider_meta: Util.normalize_struct(body)})
         |> Repo.update() do
      {:ok, command_response} ->
        {:ok, command_response}

      {:error, _reason} ->
        Logger.error("Failed to update command response #{command_response.id}")
        {:ok, command_response}
    end
  end
end
