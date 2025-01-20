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
         claim = Repo.preload(claim, source: [repository: [:user]], target: [repository: [:user]], user: []),
         {:ok, _} <- maybe_add_labels(token, claim),
         {:ok, _} <- add_comment(token, claim) do
      :ok
    end
  end

  defp add_comment(token, claim) do
    Github.create_issue_comment(
      token,
      claim.target.repository.user.provider_login,
      claim.target.repository.name,
      claim.target.number,
      "💡 @#{claim.user.provider_login} submitted [#{Claim.type_label(claim.type)}](#{claim.url}) that claims the bounty. You can visit [Algora](#{Claim.reward_url(claim)}) to reward."
    )
  end

  defp maybe_add_labels(token, %Claim{source: source} = claim) when not is_nil(source) do
    Github.add_labels(
      token,
      claim.source.repository.user.provider_login,
      claim.source.repository.name,
      claim.source.number,
      ["🙋 Bounty claim"]
    )
  end

  defp maybe_add_labels(_token, _claim), do: {:ok, nil}
end
