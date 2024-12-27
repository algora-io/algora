defmodule Algora.Github.PollerRootSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Algora.Github.PollerSupervisor,
      Supervisor.child_spec(
        {Task, &Algora.Github.PollerSupervisor.start_children/0},
        restart: :transient
      )
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
