defmodule Algora.Github.Poller.SearchConsumer do
  @moduledoc false
  use Oban.Worker, queue: :search_consumers

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace.CommandResponse

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"comment" => comment, "command" => encoded_command, "ticket_ref" => encoded_ticket_ref} = _args
      }) do
    command = Util.base64_to_term!(encoded_command)
    ticket_ref = Util.base64_to_term!(encoded_ticket_ref)

    run_command(command, ticket_ref, comment)
  end

  defp run_command({:tip, args}, ticket_ref, _comment) do
    Algora.Admin.alert("Creating global tip intent for #{inspect(args[:amount])}: #{inspect(ticket_ref)}")

    Bounties.create_tip_intent(%{
      recipient: args[:recipient],
      amount: args[:amount],
      ticket_ref: %{
        owner: ticket_ref[:owner],
        repo: ticket_ref[:repo],
        number: ticket_ref[:number]
      }
    })
  end

  defp run_command({:bounty, args}, ticket_ref, comment) do
    case Accounts.fetch_user_by(
           provider: "github",
           provider_login: to_string(comment["author"]["login"])
         ) do
      {:ok, user} ->
        strategy =
          case Repo.get_by(CommandResponse,
                 provider: "github",
                 provider_command_id: to_string(comment["databaseId"]),
                 command_source: :comment
               ) do
            nil -> :increase
            _ -> :set
          end

        Algora.Admin.alert("Creating global bounty for #{inspect(args[:amount])}: #{inspect(ticket_ref)}")

        Bounties.create_bounty(
          %{
            creator: user,
            owner: user,
            amount: args[:amount],
            ticket_ref: %{
              owner: ticket_ref[:owner],
              repo: ticket_ref[:repo],
              number: ticket_ref[:number]
            }
          },
          command_id: comment["databaseId"],
          command_source: :comment,
          strategy: strategy
        )

      {:error, _reason} = error ->
        Logger.error("Failed to create bounty: #{inspect(error)}")
        error
    end
  end

  defp run_command(command, ticket_ref, comment) do
    Algora.Admin.alert(
      "Received unknown command: #{inspect(command)}. Ticket ref: #{inspect(ticket_ref)}. URL: #{comment["url"]}"
    )
  end
end
