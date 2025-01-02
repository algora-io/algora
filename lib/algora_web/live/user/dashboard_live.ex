defmodule AlgoraWeb.User.DashboardLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Achievement
  import AlgoraWeb.Components.Bounties

  alias Algora.Bounties
  alias Algora.Bounties.Bounty

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bounties.subscribe()
    end

    socket =
      socket
      |> assign(:view_mode, "compact")
      |> assign(:available_to_work, true)
      |> assign(:hourly_rate, Money.new!(50, :USD))
      |> assign(:hours_per_week, 40)
      |> assign(:contracts, Algora.Contracts.list_contracts(open?: true, limit: 10))
      |> assign(:achievements, fetch_achievements())
      |> assign_tickets()

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 bg-background text-foreground lg:pr-96">
      <!-- Hourly Bounties Section -->
      <%= if length(@contracts) > 0 do %>
        <div class="relative mx-auto h-full max-w-4xl p-6">
          <div class="flex justify-between px-6">
            <div class="flex flex-col space-y-1.5">
              <h2 class="text-2xl font-semibold leading-none tracking-tight">
                Hourly contracts
              </h2>
              <p class="text-sm text-muted-foreground">Paid out weekly</p>
            </div>
          </div>
          <div class="-ml-4 px-6">
            <div class="relative w-full overflow-auto">
              <table class="w-full caption-bottom text-sm">
                <tbody>
                  <%= for contract <- @contracts do %>
                    <.contract_card contract={contract} />
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      <% end %>
      <!-- Regular Bounties Section -->

      <div class="relative mx-auto h-full max-w-4xl p-6">
        <.section title="Open bounties" subtitle="Bounties for you" link={~p"/bounties"}>
          <.bounties tickets={@tickets} />
        </.section>
      </div>
    </div>
    <!-- Sidebar -->
    <aside class="fixed top-16 right-0 bottom-0 hidden w-96 overflow-y-auto border-l border-border bg-background p-4 pt-6 sm:p-6 md:p-8 lg:block">
      <!-- Availability Section -->
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <label for="available" class="text-sm font-medium">Available to work</label>
          <.tooltip>
            <.icon name="tabler-help-circle" class="h-4 w-4 text-muted-foreground" />
            <.tooltip_content side="bottom" class="max-w-xs text-sm">
              When enabled, you will receive hourly contract offers
            </.tooltip_content>
          </.tooltip>
        </div>
        <.switch
          id="available"
          name="available"
          value={@available_to_work}
          phx-click="toggle_availability"
        />
      </div>
      <div class="mt-4 grid grid-cols-2 gap-4">
        <div>
          <label for="hourly-rate" class="text-sm font-medium">Hourly rate (USD)</label>
          <div class="relative mt-2">
            <span class="font-display absolute top-1/2 left-3 -translate-y-1/2">
              $
            </span>
            <.input
              type="number"
              min="0"
              id="hourly-rate"
              name="hourly-rate"
              value={@hourly_rate}
              phx-keydown="handle_hourly_rate"
              phx-debounce="200"
              phx-hook="ClearInput"
              class="font-display w-full border-input bg-background ps-6"
            />
          </div>
        </div>
        <div>
          <label for="hours-per-week" class="text-sm font-medium">Hours per week</label>
          <.input
            type="number"
            min="0"
            max="168"
            id="hours-per-week"
            name="hours-per-week"
            value={@hours_per_week}
            phx-keydown="handle_hours_per_week"
            phx-debounce="200"
            class="font-display mt-2 w-full border-input bg-background"
          />
        </div>
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
          class="mt-2 w-full border-input bg-background"
        />
        <div class="mt-4 flex flex-wrap gap-3">
          <%= for tech <- @current_user.tech_stack do %>
            <div class="rounded-lg bg-foreground/5 px-2 py-1 text-xs font-medium text-foreground ring-1 ring-inset ring-foreground/25">
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
        <h2 class="text-xl font-semibold leading-none tracking-tight">Achievements</h2>
        <.link
          class="whitespace-pre text-sm text-muted-foreground hover:underline hover:brightness-125"
          href="#"
        >
          View all
        </.link>
      </div>
      <nav class="pt-4">
        <ol role="list" class="space-y-6">
          <%= for achievement <- @achievements do %>
            <li>
              <.achievement achievement={achievement} />
            </li>
          <% end %>
        </ol>
      </nav>
    </aside>
    """
  end

  defp fetch_achievements do
    [
      %{status: :completed, name: "Personalize Algora"},
      %{status: :current, name: "Create Stripe account"},
      %{status: :upcoming, name: "Earn first bounty"},
      %{status: :upcoming, name: "Earn through referral"},
      %{status: :upcoming, name: "Earn $10K"}
    ]
  end

  def handle_event("handle_tech_input", %{"key" => "Enter", "value" => tech}, socket) when byte_size(tech) > 0 do
    tech_stack = Enum.uniq([String.trim(tech) | socket.assigns.tech_stack])

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

  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_tickets(socket)}
  end

  defp assign_tickets(socket) do
    tickets =
      Bounties.TicketView.list(
        status: :open,
        tech_stack: socket.assigns.current_user.tech_stack,
        limit: 100
      ) ++
        Bounties.TicketView.sample_tickets()

    assign(socket, :tickets, Enum.take(tickets, 6))
  end

  def compact_view(assigns) do
    ~H"""
    <tr class="h-10 border-b transition-colors hover:bg-muted/10">
      <td class="p-4 py-0 align-middle">
        <div class="flex items-center gap-4">
          <div class="font-display shrink-0 whitespace-nowrap text-base font-semibold text-success">
            {Money.to_string!(@bounty.amount)}
          </div>

          <.link
            href={@bounty.ticket.url}
            class="max-w-[400px] truncate text-sm text-foreground hover:underline"
          >
            {@bounty.ticket.title}
          </.link>

          <div class="flex shrink-0 items-center gap-1 whitespace-nowrap text-sm text-muted-foreground">
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

  def default_view(assigns) do
    ~H"""
    <tr class="border-b transition-colors hover:bg-muted/10">
      <td class="p-4 align-middle">
        <div class="flex items-center gap-4">
          <.link href={~p"/org/#{@bounty.owner.handle}"}>
            <.avatar class="h-14 w-14 rounded-xl">
              <.avatar_image src={@bounty.owner.avatar_url} alt={@bounty.owner.name} />
              <.avatar_fallback>
                {String.first(@bounty.owner.name)}
              </.avatar_fallback>
            </.avatar>
          </.link>

          <div class="flex flex-col gap-1">
            <div class="flex items-center gap-1 text-sm text-muted-foreground">
              <.link href={~p"/org/#{@bounty.owner.handle}"} class="font-semibold hover:underline">
                {@bounty.owner.name}
              </.link>
              <.icon name="tabler-chevron-right" class="h-4 w-4" />
              <.link href={@bounty.ticket.url} class="hover:underline">
                {Bounty.path(@bounty)}
              </.link>
            </div>

            <.link href={@bounty.ticket.url} class="group flex items-center gap-2">
              <div class="font-display text-xl font-semibold text-success">
                {Money.to_string!(@bounty.amount)}
              </div>
              <div class="line-clamp-1 text-foreground group-hover:underline">
                {@bounty.ticket.title}
              </div>
            </.link>

            <div class="flex flex-wrap gap-2">
              <%= for tag <- @bounty.owner.tech_stack do %>
                <span class="text-sm text-muted-foreground">
                  {tag}
                </span>
              <% end %>
            </div>
          </div>
        </div>
      </td>
    </tr>
    """
  end

  def contract_card(assigns) do
    ~H"""
    <tr class="border-b transition-colors hover:bg-muted/10">
      <td class="p-4 align-middle">
        <div class="flex items-center justify-between gap-4">
          <div class="flex items-center gap-4">
            <.link href={~p"/org/#{@contract.client.handle}"}>
              <.avatar class="aspect-[1200/630] h-32 w-auto rounded-lg">
                <.avatar_image src={@contract.client.og_image_url} alt={@contract.client.name} />
                <.avatar_fallback class="rounded-lg"></.avatar_fallback>
              </.avatar>
            </.link>

            <div class="flex flex-col gap-1">
              <div class="flex items-center gap-1 text-base text-foreground">
                <.link
                  href={~p"/org/#{@contract.client.handle}"}
                  class="font-semibold hover:underline"
                >
                  {@contract.client.og_title || @contract.client.name}
                </.link>
              </div>
              <div class="line-clamp-2 text-muted-foreground">
                {@contract.client.bio}
              </div>
              <div class="group flex items-center gap-2">
                <div
                  :if={@contract.status != :draft}
                  class="font-display text-xl font-semibold text-success"
                >
                  {Money.to_string!(@contract.hourly_rate)}/hr
                </div>
                <span class="text-sm text-muted-foreground">
                  · {@contract.hours_per_week} hours/week
                </span>
              </div>

              <div class="mt-1 flex flex-wrap gap-2">
                <%= for tag <- @contract.client.tech_stack || [] do %>
                  <div class="rounded-lg bg-foreground/5 px-2 py-1 text-xs font-medium text-foreground ring-1 ring-inset ring-foreground/25">
                    {tag}
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <div class="flex flex-col items-end gap-3">
            <div class="text-right">
              <div class="whitespace-nowrap text-sm text-muted-foreground">Total contract value</div>
              <div
                :if={@contract.status != :draft}
                class="font-display text-lg font-semibold text-foreground"
              >
                {Money.to_string!(Money.mult!(@contract.hourly_rate, @contract.hours_per_week))} / wk
              </div>
            </div>
            <.button phx-click="accept_contract" phx-value-org={@contract.client.handle} size="sm">
              <.link navigate={~p"/contracts/#{@contract.id}"}>
                Accept contract
              </.link>
            </.button>
          </div>
        </div>
      </td>
    </tr>
    """
  end
end
