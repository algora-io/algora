defmodule Algora.Payments.Jobs.ExecutePendingTransfers do
  @moduledoc false
  use Oban.Worker,
    queue: :transfers,
    max_attempts: 1

  alias Algora.Payments

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{user_id: user_id}}) do
    Payments.execute_pending_transfers(user_id)
  end
end
