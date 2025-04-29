defmodule Algora.Workspace.Jobs.FetchTopContributions do
  @moduledoc false
  use Oban.Worker,
    queue: :fetch_top_contributions,
    max_attempts: 3,
    # 30 days
    unique: [period: 30 * 24 * 60 * 60, fields: [:args]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"provider_login" => provider_login}}) do
    Algora.Workspace.fetch_top_contributions_async(provider_login)
  end

  def timeout(_), do: :timer.seconds(30)
end
