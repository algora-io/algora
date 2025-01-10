defmodule Algora.Github.Poller.CommentConsumer do
  @moduledoc false
  use Oban.Worker, queue: :comment_consumers

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Github
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
    with {:ok, user} <- Accounts.fetch_user_by(provider_id: to_string(comment["user"]["id"])),
         {:ok, amount} <- Keyword.fetch(args, :amount) do
      Bounties.create_bounty(%{
        creator: user,
        owner: user,
        amount: amount,
        ticket_ref: %{owner: ticket_ref[:owner], repo: ticket_ref[:repo], number: ticket_ref[:number]}
      })
    else
      {:error, _reason} = error ->
        Logger.error("Failed to create bounty: #{inspect(error)}")
        error
    end
  end
end
