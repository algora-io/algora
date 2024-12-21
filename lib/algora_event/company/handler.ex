defmodule AlgoraEvent.Company.Handler do
  use Commanded.Event.Handler,
    application: AlgoraEvent.Application,
    name: __MODULE__

  alias AlgoraEvent.Company
  alias AlgoraEvent.Company.Events
  require Logger

  def after_start(state) do
    Logger.info("started #{__MODULE__} with #{inspect(state)}")
    :ok
  end

  def handle(%Commanded.EventStore.RecordedEvent{} = event) do
    Logger.info("handling event #{inspect(event)}")
    # todo(ty) persist view model
    :ok
  end

end
