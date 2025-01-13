defmodule Algora.Bounties.Jobs.NotifyClaim do
  @moduledoc false
  use Oban.Worker, queue: :notify_claim

  alias Algora.Bounties.Claim
  alias Algora.Github
  alias Algora.Repo

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"claim_id" => _claim_id, "installation_id" => nil}}) do
    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"claim_id" => claim_id, "installation_id" => installation_id}}) do
    with {:ok, token} <- Github.get_installation_token(installation_id),
         {:ok, claim} <- Repo.fetch(Claim, claim_id),
         claim = Repo.preload(claim, ticket: [repository: [:user]], user: []),
         {:ok, _} <- maybe_add_labels(token, claim),
         {:ok, _} <- add_comment(token, claim) do
      :ok
    end
  end

  defp add_comment(token, claim) do
    Github.create_issue_comment(
      token,
      claim.ticket.repository.user.provider_login,
      claim.ticket.repository.name,
      claim.ticket.number,
      "💡 @#{claim.user.provider_login} submitted [#{Claim.type_label(claim.type)}](#{claim.url}) that claims the bounty. You can visit [Algora](#{Claim.reward_url(claim)}) to reward."
    )
  end

  defp maybe_add_labels(token, %Claim{type: :pull_request} = claim) do
    Github.add_labels(
      token,
      claim.provider_meta["base"]["repo"]["owner"]["login"],
      claim.provider_meta["base"]["repo"]["name"],
      claim.provider_meta["number"],
      ["🙋 Bounty claim"])
    
  end

  defp maybe_add_labels(_token, _claim), do: {:ok, nil}
end
