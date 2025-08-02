defmodule Algora.Activities.SendDiscord do
  @moduledoc false
  use Oban.Worker,
    queue: :background,
    tags: ["discord", "activities"]

  require Logger

  def changeset(attrs) do
    new(attrs)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"url" => url, "payload" => payload}}) do
    Algora.Discord.send_message(url, payload)
  end
end
