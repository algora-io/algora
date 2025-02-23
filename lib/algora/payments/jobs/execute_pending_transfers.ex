defmodule Algora.Payments.Jobs.ExecutePendingTransfer do
  @moduledoc false
  use Oban.Worker,
    queue: :transfers,
    max_attempts: 1

  alias Algora.Payments

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"credit_id" => credit_id}}) do
    Payments.execute_pending_transfer(credit_id)
  end
end
