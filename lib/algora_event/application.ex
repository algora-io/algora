defmodule AlgoraEvent.Application do
  use Commanded.Application,
    otp_app: :algora,
    event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: AlgoraEvent.Store
    ],
    pubsub: :local,
    registry: :local

  router AlgoraEvent.Router
end
