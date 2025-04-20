defmodule Algora.BotTemplates do
  @moduledoc false

  alias Algora.BotTemplates.BotTemplate
  alias Algora.Repo

  def get_default_template(:bounty_created) do
    """
    ${PRIZE_POOL}
    ### Steps to solve:
    1. **Start working**: Comment `/attempt #${ISSUE_NUMBER}` with your implementation plan
    2. **Submit work**: Create a pull request including `/claim #${ISSUE_NUMBER}` in the PR body to claim the bounty
    3. **Receive payment**: 100% of the bounty is received 2-5 days post-reward. [Make sure you are eligible for payouts](https://algora.io/docs/payments#supported-countries-regions)

    ### ❗ Important guidelines:
    - To claim a bounty, you need to **provide a short demo video** of your changes in your pull request
    - If anything is unclear, **ask for clarification** before starting as this will help avoid potential rework
    - Low quality AI PRs will not receive review and will be closed
    - Do not ask to be assigned unless you've contributed before

    Thank you for contributing to ${REPO_FULL_NAME}!
    ${ATTEMPTS}
    """
  end

  def get_default_template(_type), do: raise("Not implemented")

  def placeholders(:bounty_created, user) do
    %{
      "PRIZE_POOL" => "## 💎 $1,000 bounty [• #{user.name}](#{AlgoraWeb.Endpoint.url()}/#{user.handle})",
      "ISSUE_NUMBER" => "100",
      "REPO_FULL_NAME" => "#{user.provider_login || user.handle}/repo",
      "ATTEMPTS" => """
      | Attempt | Started (UTC) | Solution | Actions |
      | --- | --- | --- | --- |
      | 🟢 [@jsmith](https://github.com/jsmith) | #{Calendar.strftime(DateTime.utc_now(), "%b %d, %Y, %I:%M:%S %p")} | [#101](https://github.com/#{user.provider_login || user.handle}/repo/pull/101) | [Reward](#{AlgoraWeb.Endpoint.url()}/claims/:id) |
      """,
      "FUND_URL" => AlgoraWeb.Endpoint.url(),
      "TWEET_URL" =>
        "https://twitter.com/intent/tweet?related=algoraio&text=%241%2C000+bounty%21+%F0%9F%92%8E+https%3A%2F%2Fgithub.com%2F#{user.provider_login || user.handle}%2Frepo%2Fissues%2F100",
      "ADDITIONAL_OPPORTUNITIES" => ""
    }
  end

  def placeholders(_type, _user), do: raise("Not implemented")

  def available_variables(:bounty_created) do
    [
      "PRIZE_POOL",
      "ISSUE_NUMBER",
      "REPO_FULL_NAME",
      "ATTEMPTS",
      "FUND_URL",
      "TWEET_URL"
    ]
  end

  def get_template(org_id, type) do
    Repo.get_by(BotTemplate, user_id: org_id, type: type, active: true)
  end

  def save_template(org_id, type, template) do
    params = %{
      user_id: org_id,
      type: type,
      template: template,
      active: true
    }

    %BotTemplate{}
    |> BotTemplate.changeset(params)
    |> Repo.insert(
      on_conflict: [set: [template: template, active: true]],
      conflict_target: [:user_id, :type]
    )
  end
end
