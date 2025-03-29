defmodule Algora.Github.Poller.RootSupervisor do
  @moduledoc false
  use Supervisor

  alias Algora.Github.Poller.DeliverySupervisor
  alias Algora.Github.Poller.SearchSupervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      SearchSupervisor,
      Supervisor.child_spec(
        {Task, &SearchSupervisor.start_children/0},
        id: :search_supervisor,
        restart: :transient
      ),
      Supervisor.child_spec(
        {Task, &DeliverySupervisor.start_children/0},
        id: :delivery_supervisor,
        restart: :transient
      )
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
