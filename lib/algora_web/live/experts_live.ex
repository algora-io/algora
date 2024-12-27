defmodule AlgoraWeb.ExpertsLive do
  use AlgoraWeb, :live_view

  require Logger

  import AlgoraWeb.Components.Experts

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:experts, list_experts())}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 bg-background text-foreground">
      <.section title="Experts" subtitle="View all experts on Algora">
        <ul class="flex flex-col gap-8 md:grid md:grid-cols-2 xl:grid-cols-3">
          <.experts experts={@experts} />
        </ul>
      </.section>
    </div>
    """
  end
end
