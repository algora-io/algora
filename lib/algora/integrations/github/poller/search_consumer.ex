defmodule Algora.Github.Poller.SearchConsumer do
  @moduledoc false
  use Oban.Worker, queue: :search_consumers

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Util

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"comment" => comment, "command" => encoded_command, "ticket_ref" => encoded_ticket_ref} = _args
      }) do
    command = Util.base64_to_term!(encoded_command)
    ticket_ref = Util.base64_to_term!(encoded_ticket_ref)

    run_command(command, ticket_ref, comment)
  end

  defp run_command({:claim, _args}, _ticket_ref, _comment) do
    # TODO: implement claim command
    :ok
  end

  defp run_command({:tip, args}, ticket_ref, _comment) do
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
          command_source: :comment
        )

      {:error, _reason} = error ->
        Logger.error("Failed to create bounty: #{inspect(error)}")
        error
    end
  end
end
