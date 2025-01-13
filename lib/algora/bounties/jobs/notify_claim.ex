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
         {:ok, claim} <- Repo.fetch(Claim, claim_id) do
      claim = Repo.preload(claim, ticket: [repository: [:user]], user: [])

      # TODO: implement
      claim_reward_url = "#{AlgoraWeb.Endpoint.url()}/claims/#{claim.id}"

      Github.create_issue_comment(
        token,
        claim.ticket.repository.user.provider_login,
        claim.ticket.repository.name,
        claim.ticket.number,
        "💡 @#{claim.user.provider_login} submitted [#{Claim.type_label(claim.type)}](#{claim.url}) that claims the bounty. You can visit [Algora](#{claim_reward_url}) to reward."
      )
    end
  end
end
