defmodule Algora.Payments.Jobs.ExecuteTransfer do
  @moduledoc false
  use Oban.Worker, queue: :execute_transfer

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{transfer_id: transfer_id, user_id: user_id}}) do
    # TODO: execute transfer
    dbg("executing transfer #{transfer_id} for user #{user_id}")
    {:error, :not_implemented}
  end
end
