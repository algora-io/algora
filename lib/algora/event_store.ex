 defmodule Algora.EventStore do
   use EventStore, otp_app: :algora

   def init(config) do
     {:ok, config}
   end
 end
