defmodule Algora.Activities.Notifier do
  @moduledoc false
  use Oban.Worker,
    queue: :activities,
    max_attempts: 3,
    tags: ["mail", "activities"]

  # unique: [period: 30]

  def changeset(activity, target) do
    new(%{activity_id: activity.id, target_id: target.id})
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{}} = job) do
    IO.inspect(job)
    :ok
  end
end
