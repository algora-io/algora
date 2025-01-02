defmodule AlgoraWeb.ExpertsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Experts

  alias Algora.Accounts

  require Logger

  def mount(_params, _session, socket) do
    techs = Accounts.list_techs()
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
    assign(socket, :experts, Accounts.list_experts(socket.assigns.tech))
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6">
      <.section title="Experts" subtitle="View all experts on Algora">
        <div class="-mt-4 mb-4 flex flex-wrap gap-2">
          <%= for tech <- @techs do %>
            <div
              phx-click="select_tech"
              phx-value-tech={tech}
              class={[
                "#{if tech == @tech, do: "bg-white/[4%] border-white/20", else: "bg-white/[2%] border-white/10"} group/card from-white/[2%] via-white/[2%] to-white/[2%] group relative h-full min-w-14 cursor-pointer rounded-xl border bg-gradient-to-br p-2 text-center hover:bg-white/[4%] hover:border-white/15 md:gap-8"
              ]}
            >
              <div class="pointer-events-none">
                <div class="[mask-image:linear-gradient(black,transparent)] absolute inset-0 z-0 opacity-0 group-hover/card:opacity-100">
                </div>
                <div
                  class="via-white/[2%] absolute inset-0 z-10 bg-gradient-to-br opacity-0 group-hover/card:opacity-100"
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
