defmodule Algora.Bounties.Jobs.NotifyTransfer do
  @moduledoc false
  use Oban.Worker, queue: :notify_transfer

  import Ecto.Query

  alias Algora.Bounties.Ticket
  alias Algora.Github
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Workspace.Ticket

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"transaction_id" => transaction_id}}) do
    with {:ok, ticket} <-
           Repo.fetch_one(
             from t in Ticket,
               left_join: bounty in assoc(t, :bounties),
               left_join: tip in assoc(t, :tips),
               left_join: tx in Transaction,
               on: tx.bounty_id == bounty.id or tx.tip_id == tip.id,
               join: repo in assoc(t, :repository),
               join: user in assoc(repo, :user),
               where: tx.id == ^transaction_id,
               select_merge: %{
                 repository: %{repo | user: user}
               }
           ),
         ticket_ref = %{
           owner: ticket.repository.user.provider_login,
           repo: ticket.repository.name,
           number: ticket.number
         },
         {:ok, transaction} <-
           Repo.fetch_one(
             from tx in Transaction,
               join: user in assoc(tx, :user),
               where: tx.id == ^transaction_id,
               where: tx.type == :transfer,
               select_merge: %{user: user}
           ) do
      installation = Repo.get(Installation, connected_user_id: ticket.repository.user.id)
      body = "🎉🎈 @#{transaction.user.provider_login} has been awarded **#{transaction.net_amount}**! 🎈🎊"

      do_perform(ticket_ref, body, installation)
    end
  end

  defp do_perform(ticket_ref, body, nil) do
    Github.try_without_installation(&Github.create_issue_comment/5, [
      ticket_ref["owner"],
      ticket_ref["repo"],
      ticket_ref["number"],
      body
    ])
  end

  defp do_perform(ticket_ref, body, installation) do
    {:ok, token} = Github.get_installation_token(installation.id)
    Github.create_issue_comment(token, ticket_ref["owner"], ticket_ref["repo"], ticket_ref["number"], body)
  end
end
