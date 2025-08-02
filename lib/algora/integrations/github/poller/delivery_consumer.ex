defmodule Algora.Github.Poller.DeliveryConsumer do
  @moduledoc false
  use Oban.Worker, queue: :background

  import Ecto.Query

  alias Algora.Github
  alias Algora.Repo

  require Logger

  @max_attempts 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"delivery" => delivery} = _args}) do
    attempts_count =
      Repo.one(
        from(j in "oban_jobs",
          where: fragment("(args->>'delivery')::jsonb->>'guid' = ?", ^delivery["guid"]),
          select: count(j.id)
        )
      ) || 0

    if attempts_count <= @max_attempts do
      Github.redeliver(delivery["id"])
    else
      Algora.Activities.alert("Max attempts reached for delivery #{delivery["id"]}", :error)
      :discard
    end
  end
end
