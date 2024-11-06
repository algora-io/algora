ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Algora.Repo, :manual)

defmodule Finch.Behaviour do
  @callback request(Finch.Request.t(), Finch.name(), keyword()) ::
              {:ok, Finch.Response.t()} | {:error, Exception.t()}

  @callback request(Finch.Request.t(), Finch.name()) ::
              {:ok, Finch.Response.t()} | {:error, Exception.t()}
end

# Set up Mox with shared mode
Mox.defmock(Finch.Mock, for: Finch.Behaviour)
Application.put_env(:algora, :finch_module, Finch.Mock)
