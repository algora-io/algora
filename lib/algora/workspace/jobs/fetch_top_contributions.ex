defmodule Algora.Workspace.Jobs.FetchTopContributions do
  @moduledoc false
  use Oban.Worker,
    queue: :fetch_top_contributions,
    max_attempts: 3

  alias Algora.Github

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"provider_logins" => provider_logins}}) do
    Algora.Workspace.fetch_top_contributions_async(Github.TokenPool.get_token(), provider_logins)
  end

  def timeout(_), do: :timer.seconds(30)
end
