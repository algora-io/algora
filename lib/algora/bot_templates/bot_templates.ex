defmodule Algora.BotTemplates do
  @moduledoc false

  def get_default_template(:bounty_created) do
    """
    ${PRIZE_POOL}
    ### Steps to solve:
    1. **Start working**: Comment `/attempt #${ISSUE_NUMBER}` with your implementation plan
    2. **Submit work**: Create a pull request including `/claim #${ISSUE_NUMBER}` in the PR body to claim the bounty
    3. **Receive payment**: 100% of the bounty is received 2-5 days post-reward. [Make sure you are eligible for payouts](https://docs.algora.io/bounties/payments#supported-countries-regions)

    Thank you for contributing to ${REPO_FULL_NAME}!
    ${ATTEMPTS}
    """
  end

  def get_default_template(_type) do
    raise "Not implemented"
  end
end
