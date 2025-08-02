defmodule Algora.Payments.Jobs.ExecutePendingTransfer do
  @moduledoc false
  use Oban.Worker,
    queue: :default,
    unique: [period: :infinity]

  alias Algora.Payments

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"credit_id" => credit_id}}) do
    Payments.execute_pending_transfer(credit_id)
  end
end
