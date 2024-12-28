defmodule Algora.Github.Poller.RootSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Algora.Github.Poller.Supervisor,
      Supervisor.child_spec(
        {Task, &Algora.Github.Poller.Supervisor.start_children/0},
        restart: :transient
      )
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
