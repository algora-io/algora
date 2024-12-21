 defmodule AlgoraEvent.Store do
   use EventStore, otp_app: :algora, schema: "console"

   def init(config) do
     {:ok, config}
   end
 end
