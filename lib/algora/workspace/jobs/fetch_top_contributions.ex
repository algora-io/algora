defmodule Algora.Workspace.Jobs.FetchTopContributions do
  @moduledoc false
  use Oban.Worker,
    queue: :internal,
    max_attempts: 2,
    unique: [period: 30 * 24 * 60 * 60, fields: [:args]]

  alias Algora.Github

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"provider_logins" => provider_logins}}) do
    Algora.Workspace.fetch_top_contributions_async(Github.TokenPool.get_token(), provider_logins)
  end

  def timeout(_), do: to_timeout(second: 30)
end
