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

    run_command(command, ticket_ref, comment)
  end

  defp run_command({:tip, args}, ticket_ref, comment) do
    amount = Keyword.get(args, :amount)
    recipient = Keyword.get(args, :username)
    owner = Keyword.get(ticket_ref, :owner)
    repo = Keyword.get(ticket_ref, :repo)
    number = Keyword.get(ticket_ref, :number)

    query = URI.encode_query(amount: Money.to_decimal(amount), recipient: recipient)
    url = AlgoraWeb.Endpoint.url() <> "/tip" <> "?" <> query
    body = "Please visit [Algora](#{url}) to complete your tip via Stripe."

    if Github.pat_enabled() do
      Github.create_issue_comment(Github.pat(), owner, repo, number, body)
    else
      Logger.info("""
      Github.create_issue_comment(Github.pat(), "#{owner}", "#{repo}", #{number},
             \"\"\"
             #{body}
             \"\"\")
      """)

      :ok
    end
  end

  defp run_command({:bounty, args}, ticket_ref, comment) do
    # TODO: use user's own token if available
    token = Github.TokenPool.get_token()

    owner = Keyword.get(ticket_ref, :owner)
    repo = Keyword.get(ticket_ref, :repo)
    number = Keyword.get(ticket_ref, :number)

    with {:ok, amount} <- Keyword.fetch(args, :amount),
         {:ok, user} <- Workspace.ensure_user(token, extract_actor(comment)),
         {:ok, ticket} <- Workspace.ensure_ticket(token, owner, repo, number),
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
