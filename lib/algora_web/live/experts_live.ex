defmodule AlgoraWeb.ExpertsLive do
  use AlgoraWeb, :live_view

  require Logger

  import AlgoraWeb.Components.Experts

  def mount(_params, _session, socket) do
    techs = list_techs()
    tech = List.first(techs)

    {:ok,
     socket
     |> assign(:techs, techs)
     |> assign(:tech, tech)
     |> assign_experts()}
  end

  def handle_event("select_tech", %{"tech" => tech}, socket) do
    {:noreply,
     socket
     |> assign(:tech, tech)
     |> assign_experts()}
  end

  defp assign_experts(socket) do
    socket |> assign(:experts, list_experts(socket.assigns.tech))
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 bg-background text-foreground">
      <.section title="Experts" subtitle="View all experts on Algora">
        <div class="-mt-4 mb-4 flex flex-wrap gap-2">
          <%= for tech <- @techs do %>
            <div
              phx-click="select_tech"
              phx-value-tech={tech}
              class={["group/card relative h-full rounded-xl border min-w-14 text-center
                     #{if tech == @tech, do: "border-white/20 bg-white/[4%]", else: "border-white/10 bg-white/[2%]"}
                     bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] md:gap-8
                     hover:border-white/15 hover:bg-white/[4%] group cursor-pointer p-2"]}
            >
              <div class="pointer-events-none">
                <div class="absolute inset-0 z-0 opacity-0 [mask-image:linear-gradient(black,transparent)] group-hover/card:opacity-100">
                </div>
                <div
                  class="absolute inset-0 z-10 bg-gradient-to-br via-white/[2%] opacity-0 group-hover/card:opacity-100"
                  style="mask-image: radial-gradient(240px at 0px 0px, white, transparent);"
                >
                </div>
                <div
                  class="absolute inset-0 z-10 opacity-0 mix-blend-overlay group-hover/card:opacity-100"
                  style="mask-image: radial-gradient(240px at 0px 0px, white, transparent);"
                >
                </div>
              </div>
              <span class="text-sm font-medium text-white/90 group-hover:text-white">
                {tech}
              </span>
            </div>
          <% end %>
        </div>
        <ul class="flex flex-col gap-8 md:grid md:grid-cols-2 xl:grid-cols-3">
          <.experts experts={@experts} />
        </ul>
      </.section>
    </div>
    """
  end
end
