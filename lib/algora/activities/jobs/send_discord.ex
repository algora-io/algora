defmodule Algora.Activities.SendDiscord do
  @moduledoc false
  use Oban.Worker,
    queue: :activity_discord,
    tags: ["discord", "activities"]

  require Logger

  def changeset(attrs) do
    new(attrs)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"payload" => payload}}) do
    Algora.Discord.send_message(payload)
  end
end
