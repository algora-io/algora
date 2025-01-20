defmodule Algora.Activities.SendEmail do
  @moduledoc false
  use Oban.Worker,
    queue: :activity_mailer,
    max_attempts: 1,
    tags: ["email", "activities"]

  # unique: [period: 30]

  def changeset(attrs) do
    new(attrs)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{}} = job) do
    IO.inspect(job)
    :ok
  end
end
