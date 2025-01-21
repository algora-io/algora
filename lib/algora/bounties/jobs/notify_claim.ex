defmodule Algora.Bounties.Jobs.NotifyClaim do
  @moduledoc false
  use Oban.Worker, queue: :notify_claim

  import Ecto.Query

  alias Algora.Bounties.Claim
  alias Algora.Github
  alias Algora.Repo

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"claim_group_id" => _claim_group_id, "installation_id" => nil}}) do
    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"claim_group_id" => claim_group_id, "installation_id" => installation_id}}) do
    with {:ok, token} <- Github.get_installation_token(installation_id),
         claims =
           from(c in Claim,
             where: c.group_id == ^claim_group_id,
             order_by: [asc: c.inserted_at]
           )
           |> Repo.all()
           |> Repo.preload([:user, source: [repository: [:user]], target: [repository: [:user]]]),
         {:ok, _} <- maybe_add_labels(token, claims),
         {:ok, _} <- add_comment(token, claims) do
      :ok
    end
  end

  defp add_comment(token, claims) do
    primary_claim = List.first(claims)

    Github.create_issue_comment(
      token,
      primary_claim.target.repository.user.provider_login,
      primary_claim.target.repository.name,
      primary_claim.target.number,
      "💡 #{names(claims)} submitted [#{Claim.type_label(primary_claim.type)}](#{primary_claim.url}) that claims the bounty. You can visit [Algora](#{Claim.reward_url(primary_claim)}) to reward."
    )
  end

  defp maybe_add_labels(token, claims) do
    primary_claim = List.first(claims)

    if primary_claim.source do
      Github.add_labels(
        token,
        primary_claim.source.repository.user.provider_login,
        primary_claim.source.repository.name,
        primary_claim.source.number,
        ["🙋 Bounty claim"]
      )
    else
      {:ok, nil}
    end
  end

  defp names([claim]) do
    claim.user.provider_login
  end

  defp names([c1, c2]) do
    "#{c1.user.provider_login} and #{c2.user.provider_login}"
  end

  defp names([c1, c2, c3]) do
    "#{c1.user.provider_login}, #{c2.user.provider_login} and #{c3.user.provider_login}"
  end

  defp names([c1, c2 | claims]) do
    "#{c1.user.provider_login}, #{c2.user.provider_login} and #{length(claims)} others"
  end
end
