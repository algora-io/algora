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
         {:ok, credit_tx} <-
           Repo.fetch_one(
             from tx in Transaction,
               join: user in assoc(tx, :user),
               where: tx.type == :credit,
               where: tx.id == ^credit_id,
               select_merge: %{user: user}
           ),
         {:ok, debit_tx} <-
           Repo.fetch_one(
             from tx in Transaction,
               join: user in assoc(tx, :user),
               where: tx.type == :debit,
               where: tx.group_id == ^credit_tx.group_id,
               select_merge: %{user: user},
               limit: 1
           ) do
      installation = Repo.get_by(Installation, provider_user_id: ticket.repository.user.id)

      reward_type =
        cond do
          credit_tx.tip_id -> "tip"
          credit_tx.bounty_id -> "bounty"
          credit_tx.contract_id -> "contract"
          true -> raise "Unknown transaction type"
        end

      body =
        "@#{credit_tx.user.provider_login}: You've been awarded a **#{credit_tx.net_amount}** by **#{debit_tx.user.name}**! 👉 [Complete your Algora onboarding](#{@onboarding_url}) to collect the #{reward_type}."

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
