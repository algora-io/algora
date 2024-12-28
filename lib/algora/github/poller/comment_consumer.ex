defmodule Algora.Github.Poller.CommentConsumer do
  use Oban.Worker, queue: :comment_consumers
  require Logger
  alias Algora.Bounties
  alias Algora.Workspace
  alias Algora.Github
  alias Algora.Util

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "comment" => comment,
            "command" => encoded_command,
            "ticket_ref" => encoded_ticket_ref
          } = _args
      }) do
    command = Util.base64_to_term!(encoded_command)
    ticket_ref = Util.base64_to_term!(encoded_ticket_ref)

    dbg(command)
    dbg(ticket_ref)

    run_command(command, ticket_ref, comment)
  end

  defp run_command({:bounty, args}, ticket_ref, comment) do
    # TODO: use user's own token if available
    token = Github.TokenPool.get_token()

    with {:ok, amount} <- Keyword.fetch(args, :amount),
         {:ok, user} <- Workspace.ensure_user(token, extract_actor(comment)),
         {:ok, ticket} <-
           Workspace.ensure_ticket(
             token,
             Keyword.get(ticket_ref, :owner),
             Keyword.get(ticket_ref, :repo),
             Keyword.get(ticket_ref, :number)
           ),
         {:ok, _bounty} <-
           Bounties.create_bounty(%{
             creator: user,
             owner: user,
             amount: amount,
             ticket: ticket
           }) do
      :ok
    else
      {:error, _reason} = error ->
        Logger.error("Failed to create bounty: #{inspect(error)}")
        error
    end
  end

  defp extract_actor(%{"user" => %{"login" => login}}), do: login
end
