defmodule Algora.Github.CommandWorker do
  use Oban.Worker, queue: :command_workers
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"event" => event, "command" => command} = args}) do
    command =
      command
      |> Base.decode64!()
      |> :erlang.binary_to_term()

    dbg(command)

    # TODO: run command
    :ok
  end
end
