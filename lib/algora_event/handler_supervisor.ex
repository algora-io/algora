defmodule AlgoraEvent.HandlerSupervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      AlgoraEvent.Company.Handler,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
