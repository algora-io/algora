defmodule AlgoraWeb.Community.DashboardLive do
  use AlgoraWeb, :live_view
  alias Algora.Bounties
  alias Algora.Bounties.Bounty

  def mount(_params, _session, socket) do
    tech_stack = ["Swift"]

    socket =
      socket
      |> assign(:tech_stack, tech_stack)
      |> assign(:hours_per_week, 40)
      |> assign(
        :bounties,
        Bounties.list_bounties(status: :open, tech_stack: tech_stack, limit: 20)
      )
      |> assign(:achievements, fetch_achievements())
      |> assign(:looking_to_collaborate, true)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 lg:pr-96 bg-background text-foreground">
      <!-- Regular Bounties Section -->
      <div class="relative h-full max-w-4xl mx-auto p-6">
        <div class="flex justify-between px-6">
          <div class="flex flex-col space-y-1.5">
            <h2 class="text-2xl font-semibold leading-none tracking-tight">Swift bounties</h2>
            <p class="text-sm text-muted-foreground">
              Bounties for Swift developers
            </p>
          </div>
        </div>
        <div class="px-6 pt-3 -ml-4">
          <div class="relative w-full overflow-auto">
            <table class="w-full caption-bottom text-sm">
              <tbody>
                <%= for bounty <- @bounties do %>
                  <.compact_view bounty={bounty} />
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    <!-- Sidebar -->
    <aside class="fixed bottom-0 right-0 top-16 hidden w-96 overflow-y-auto border-l border-border bg-background p-4 pt-6 lg:block sm:p-6 md:p-8 scrollbar-thin">
      <!-- Availability Section -->
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <label for="available" class="text-sm font-medium">I'm looking to collaborate</label>
          <.tooltip>
            <.icon name="tabler-help-circle" class="h-4 w-4 text-muted-foreground" />
            <.tooltip_content side="bottom" class="max-w-xs text-sm">
              When enabled, developers will be able to see your hourly rate and contact you.
            </.tooltip_content>
          </.tooltip>
        </div>
        <.switch
          id="available"
          name="available"
          value={@looking_to_collaborate}
          phx-click="toggle_availability"
        />
      </div>
      <div class="mt-4 grid grid-cols-2 gap-4">
        <.input
          name="hourly-rate-min"
          value=""
          phx-debounce="200"
          class="w-full bg-background border-input font-display"
          icon="tabler-currency-dollar"
          label="Min hourly rate (USD)"
        />
        <.input
          name="hourly-rate-max"
          value=""
          phx-debounce="200"
          class="w-full bg-background border-input font-display"
          icon="tabler-currency-dollar"
          label="Max hourly rate (USD)"
        />
      </div>
      <!-- Tech Stack Section -->
      <div class="mt-4">
        <label for="tech-input" class="text-sm font-medium">Tech stack</label>
        <.input
          id="tech-input"
          name="tech-input"
          value=""
          type="text"
          placeholder="Elixir, Phoenix, PostgreSQL, etc."
          phx-keydown="handle_tech_input"
          phx-debounce="200"
          phx-hook="ClearInput"
          class="mt-2 w-full bg-background border-input"
        />
        <div class="flex flex-wrap gap-3 mt-4">
          <%= for tech <- @tech_stack do %>
            <div class="ring-foreground/25 ring-1 ring-inset bg-foreground/5 text-foreground rounded-lg px-2 py-1 text-xs font-medium">
              {tech}
              <button
                phx-click="remove_tech"
                phx-value-tech={tech}
                class="ml-1 text-foreground hover:text-foreground/80"
              >
                ×
              </button>
            </div>
          <% end %>
        </div>
      </div>
      <!-- Achievements Section -->
      <div class="mt-8 flex items-center justify-between">
        <h2 class="text-xl font-semibold leading-none tracking-tight">Getting started</h2>
      </div>
      <nav class="pt-6">
        <ol role="list" class="space-y-6">
          <%= for achievement <- @achievements do %>
            <li>
              <.achievement achievement={achievement} />
            </li>
          <% end %>
        </ol>
      </nav>
      <div class="pt-8 opacity-0">
        <.link href="https://algora.io/challenges/golem">
          <img src={~p"/images/golem-challenge.png"} alt="Golem Challenge" class="aspect-video block" />
        </.link>
      </div>
    </aside>
    """
  end

  defp fetch_achievements() do
    [
      %{status: :completed, name: "Personalize Algora"},
      %{status: :current, name: "Create first bounty"},
      %{status: :upcoming, name: "Reward first bounty"},
      %{status: :upcoming, name: "Start contract with a developer"},
      %{status: :upcoming, name: "Complete first contract"}
    ]
  end

  def achievement(%{achievement: %{status: :completed}} = assigns) do
    ~H"""
    <.link href="#" class="group flex items-center gap-3">
      <div class="flex h-5 w-5 items-center justify-center text-success">
        <.icon name="tabler-circle-check-filled" class="h-5 w-5" />
      </div>
      <span class="text-sm font-medium text-success group-hover:text-muted">
        {@achievement.name}
      </span>
    </.link>
    """
  end

  def achievement(%{achievement: %{status: :upcoming}} = assigns) do
    ~H"""
    <.link href="#" class="group flex items-center gap-3">
      <div class="flex h-5 w-5 items-center justify-center">
        <div class="h-2 w-2 rounded-full bg-muted-foreground group-hover:bg-muted"></div>
      </div>
      <span class="text-sm font-medium text-muted-foreground group-hover:text-muted">
        {@achievement.name}
      </span>
    </.link>
    """
  end

  def achievement(%{achievement: %{status: :current}} = assigns) do
    ~H"""
    <.link href="#" class="flex items-start" aria-current="step">
      <span class="relative flex h-5 w-5 flex-shrink-0 items-center justify-center" aria-hidden="true">
        <span class="absolute h-5 w-5 rounded-full bg-success/25 animate-pulse"></span>
        <span class="relative block h-2 w-2 rounded-full bg-success"></span>
      </span>
      <span class="ml-3 text-sm font-medium text-muted-foreground group-hover:text-muted">
        {@achievement.name}
      </span>
    </.link>
    """
  end

  def handle_event("handle_tech_input", %{"key" => "Enter", "value" => tech}, socket)
      when byte_size(tech) > 0 do
    tech_stack = [String.trim(tech) | socket.assigns.tech_stack] |> Enum.uniq()

    {:noreply,
     socket
     |> assign(:tech_stack, tech_stack)
     |> assign(:bounties, Bounties.list_bounties(tech_stack: tech_stack, limit: 10))
     |> push_event("clear-input", %{selector: "[phx-keydown='handle_tech_input']"})}
  end

  def handle_event("handle_tech_input", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("remove_tech", %{"tech" => tech}, socket) do
    tech_stack = List.delete(socket.assigns.tech_stack, tech)

    {:noreply,
     socket
     |> assign(:tech_stack, tech_stack)
     |> assign(:bounties, Bounties.list_bounties(tech_stack: tech_stack, limit: 10))}
  end

  def handle_event("view_mode", %{"value" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, mode)}
  end

  def handle_event("accept_contract", %{"org" => _org_handle}, socket) do
    # TODO: Implement contract acceptance logic
    {:noreply, socket}
  end

  def compact_view(assigns) do
    ~H"""
    <tr class="border-b transition-colors hover:bg-muted/10 h-10">
      <td class="p-4 py-0 align-middle">
        <div class="flex items-center gap-4">
          <div class="font-display text-base font-semibold text-success whitespace-nowrap shrink-0">
            {Money.to_string!(@bounty.amount)}
          </div>

          <.link
            href={@bounty.ticket.url}
            class="truncate text-sm text-foreground hover:underline max-w-[400px]"
          >
            {@bounty.ticket.title}
          </.link>

          <div class="flex items-center gap-1 text-sm text-muted-foreground whitespace-nowrap shrink-0">
            <.link href={~p"/org/#{@bounty.owner.handle}"} class="font-semibold hover:underline">
              {@bounty.owner.name}
            </.link>
            <.icon name="tabler-chevron-right" class="h-4 w-4" />
            <.link href={@bounty.ticket.url} class="hover:underline">
              {Bounty.path(@bounty)}
            </.link>
          </div>
        </div>
      </td>
    </tr>
    """
  end
end
