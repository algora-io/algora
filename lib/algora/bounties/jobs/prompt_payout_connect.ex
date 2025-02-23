defmodule Algora.Bounties.Jobs.PromptPayoutConnect do
  @moduledoc false
  use Oban.Worker, queue: :prompt_payout_connect

  import Ecto.Query

  alias Algora.Bounties.Ticket
  alias Algora.Github
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Ticket

  require Logger

  # TODO: confirm url
  @onboarding_url "https://console.algora.io/solve"

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"credit_id" => credit_id}}) do
    with {:ok, ticket} <-
           Repo.fetch_one(
             from t in Ticket,
               left_join: bounty in assoc(t, :bounties),
               left_join: tip in assoc(t, :tips),
               left_join: tx in Transaction,
               on: tx.bounty_id == bounty.id or tx.tip_id == tip.id,
               join: repo in assoc(t, :repository),
               join: user in assoc(repo, :user),
               where: tx.id == ^credit_id,
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
               left_join: linked_tx in Transaction,
               on: linked_tx.id == tx.linked_transaction_id,
               left_join: sender in assoc(linked_tx, :user),
               where: tx.id == ^credit_id,
               select_merge: %{
                 user: user,
                 linked_transaction: %{linked_tx | user: sender}
               }
           ) do
      installation = Repo.get_by(Installation, provider_user_id: ticket.repository.user.id)

      reward_type =
        cond do
          transaction.tip_id -> "tip"
          transaction.bounty_id -> "bounty"
          transaction.contract_id -> "contract"
          true -> raise "Unknown transaction type"
        end

      body =
        "@#{transaction.user.provider_login}: You've been awarded a **#{transaction.net_amount}** #{reward_type} #{if transaction.linked_transaction, do: "by **#{transaction.linked_transaction.user.name}**", else: ""}! 👉 [Complete your Algora onboarding](#{@onboarding_url}) to collect the #{reward_type}."

      do_perform(ticket_ref, body, installation)
    end
  end

  defp do_perform(ticket_ref, body, nil) do
    Github.try_without_installation(&Github.create_issue_comment/5, [
      ticket_ref.owner,
      ticket_ref.repo,
      ticket_ref.number,
      body
    ])
  end

  defp do_perform(ticket_ref, body, installation) do
    with {:ok, token} <- Github.get_installation_token(installation.provider_id) do
      Github.create_issue_comment(token, ticket_ref.owner, ticket_ref.repo, ticket_ref.number, body)
    end
  end
end
