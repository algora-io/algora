defmodule AlgoraWeb.User.DashboardLive do
  use AlgoraWeb, :live_view
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Money

  def mount(_params, _session, socket) do
    tech_stack = ["Rust", "Elixir"]

    socket =
      socket
      |> assign(:tech_stack, tech_stack)
      |> assign(:view_mode, "compact")
      |> assign(:available_to_work, true)
      |> assign(:hourly_rate, 50)
      |> assign(:hours_per_week, 40)
      |> assign(
        :bounties,
        Bounties.list_bounties(status: :open, tech_stack: tech_stack, limit: 20)
      )
      |> assign(:hourly_bounties, fetch_hourly_bounties())
      |> assign(:achievements, fetch_achievements())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 lg:pr-96 bg-background text-foreground">
      <!-- Hourly Bounties Section -->
      <div class="relative h-full max-w-4xl mx-auto p-6">
        <div class="flex justify-between px-6">
          <div class="flex flex-col space-y-1.5">
            <h2 class="text-2xl font-semibold leading-none tracking-tight">
              Hourly contracts
            </h2>
            <p class="text-sm text-muted-foreground">Paid out weekly</p>
          </div>
        </div>
        <div class="px-6 -ml-4">
          <div class="relative w-full overflow-auto">
            <table class="w-full caption-bottom text-sm">
              <tbody>
                <%= for bounty <- @hourly_bounties do %>
                  <.default_view bounty={bounty} />
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
      <!-- Regular Bounties Section -->
      <div class="relative h-full max-w-4xl mx-auto p-6">
        <div class="flex justify-between px-6">
          <div class="flex flex-col space-y-1.5">
            <h2 class="text-2xl font-semibold leading-none tracking-tight">Bounties for you</h2>
            <p class="text-sm text-muted-foreground">Based on your tech stack</p>
          </div>
          <.toggle_group :let={builder} type="single" value={@view_mode}>
            <.toggle_group_item builder={builder} value="default" class="gap-2" phx-click="view_mode">
              <.icon name="tabler-layout-list" class="h-4 w-4" />
              <span class="sr-only">Default view</span>
            </.toggle_group_item>
            <.toggle_group_item builder={builder} value="compact" class="gap-2" phx-click="view_mode">
              <.icon name="tabler-baseline-density-medium" class="h-4 w-4" />
              <span class="sr-only">Compact view</span>
            </.toggle_group_item>
          </.toggle_group>
        </div>
        <div class="px-6 pt-3 -ml-4">
          <div class="relative w-full overflow-auto">
            <table class="w-full caption-bottom text-sm">
              <tbody>
                <%= for bounty <- @bounties do %>
                  <%= if @view_mode == "compact" do %>
                    <.compact_view bounty={bounty} />
                  <% else %>
                    <.default_view bounty={bounty} />
                  <% end %>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    <!-- Sidebar -->
    <aside class="fixed bottom-0 right-0 top-16 hidden w-96 overflow-y-auto border-l border-border bg-background p-4 pt-6 lg:block sm:p-6 md:p-8">
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
          <div class="mt-2 relative">
            <span class="absolute left-3 top-1/2 -translate-y-1/2 font-display">
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
              class="w-full bg-background border-input font-display ps-6"
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
            class="mt-2 w-full bg-background border-input font-display"
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
          class="mt-2 w-full bg-background border-input"
        />
        <div class="flex flex-wrap gap-3 mt-4">
          <%= for tech <- @tech_stack do %>
            <div class="ring-foreground/25 ring-1 ring-inset bg-foreground/5 text-foreground rounded-lg px-2 py-1 text-xs font-medium">
              <%= tech %>
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
      %{status: :current, name: "Create Stripe account"},
      %{status: :upcoming, name: "Earn first bounty"},
      %{status: :upcoming, name: "Earn through referral"},
      %{status: :upcoming, name: "Earn $10K"}
    ]
  end

  defp fetch_hourly_bounties do
    [
      %{
        amount: Decimal.new(75),
        currency: "USD",
        expected_hours: 20,
        task: %{title: "Algora: Open source bounties"},
        owner: %{
          handle: "algora",
          name: "Algora",
          og_image_url: "https://algora.io/og.png",
          avatar_url:
            "https://console.algora.io/asset/storage/v1/object/public/images/org/clcq81tsi0001mj08ikqffh87-1715034576051"
        },
        tech_stack: ["Elixir", "Phoenix", "Membrane"],
        hourly: true
      },
      %{
        amount: Decimal.new(150),
        currency: "USD",
        expected_hours: 15,
        task: %{title: "Deploy invincible backends | Golem"},
        owner: %{
          handle: "golemcloud",
          name: "Golem Cloud",
          og_image_url:
            "https://cdn.prod.website-files.com/64721eeec7cd7ef4f6f1683e/64c7adf49bfa809ce0c06161_og-golem.png",
          avatar_url:
            "https://console.algora.io/_next/image?url=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F133607167%3Fs%3D200%26v%3D4&w=1920&q=75"
        },
        tech_stack: ["Rust", "WASM"],
        hourly: true
      },
      %{
        amount: Decimal.new(150),
        currency: "USD",
        expected_hours: 25,
        task: %{title: "Qdrant - Vector Database"},
        owner: %{
          handle: "qdrant",
          name: "Qdrant",
          og_image_url: "https://qdrant.tech/images/previews/social-preview-A.png",
          avatar_url: "https://qdrant.tech/favicon/favicon.ico"
        },
        tech_stack: ["Rust"],
        hourly: true
      }
    ]
  end

  def achievement(%{achievement: %{status: :completed}} = assigns) do
    ~H"""
    <.link href="#" class="group flex items-center gap-3">
      <div class="flex h-5 w-5 items-center justify-center text-success">
        <.icon name="tabler-circle-check-filled" class="h-5 w-5" />
      </div>
      <span class="text-sm font-medium text-success group-hover:text-muted">
        <%= @achievement.name %>
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
        <%= @achievement.name %>
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
        <%= @achievement.name %>
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

  def compact_view(%{bounty: %{hourly: true}} = assigns) do
    ~H"""
    <tr class="border-b transition-colors hover:bg-muted/10 h-10">
      <td class="p-4 py-0 align-middle">
        <div class="flex items-center gap-4">
          <div class="font-display text-base font-semibold text-success whitespace-nowrap shrink-0">
            <%= Money.format!(@bounty.amount, @bounty.currency) %>/hr
          </div>

          <.link
            navigate={~p"/org/#{@bounty.owner.handle}"}
            class="truncate text-sm text-foreground hover:underline max-w-[400px]"
          >
            <%= @bounty.task.title %>
          </.link>

          <div class="flex items-center gap-1 text-sm text-muted-foreground whitespace-nowrap shrink-0">
            <.link href={~p"/org/#{@bounty.owner.handle}"} class="font-semibold hover:underline">
              <%= @bounty.owner.name %>
            </.link>
          </div>
        </div>
      </td>
    </tr>
    """
  end

  def compact_view(assigns) do
    ~H"""
    <tr class="border-b transition-colors hover:bg-muted/10 h-10">
      <td class="p-4 py-0 align-middle">
        <div class="flex items-center gap-4">
          <div class="font-display text-base font-semibold text-success whitespace-nowrap shrink-0">
            <%= Money.format!(@bounty.amount, @bounty.currency) %>
          </div>

          <.link
            href={Bounty.url(@bounty)}
            class="truncate text-sm text-foreground hover:underline max-w-[400px]"
          >
            <%= @bounty.task.title %>
          </.link>

          <div class="flex items-center gap-1 text-sm text-muted-foreground whitespace-nowrap shrink-0">
            <.link href={~p"/org/#{@bounty.owner.handle}"} class="font-semibold hover:underline">
              <%= @bounty.owner.name %>
            </.link>
            <.icon name="tabler-chevron-right" class="h-4 w-4" />
            <.link href={Bounty.url(@bounty)} class="hover:underline">
              <%= Bounty.path(@bounty) %>
            </.link>
          </div>
        </div>
      </td>
    </tr>
    """
  end

  def default_view(%{bounty: %{hourly: true}} = assigns) do
    ~H"""
    <tr class="border-b transition-colors hover:bg-muted/10">
      <td class="p-4 align-middle">
        <div class="flex items-center justify-between gap-4">
          <div class="flex items-center gap-4">
            <.link href={~p"/org/#{@bounty.owner.handle}"}>
              <.avatar class="h-32 w-auto aspect-[1200/630] rounded-lg">
                <.avatar_image src={@bounty.owner.og_image_url} alt={@bounty.owner.name} />
                <.avatar_fallback class="rounded-lg"></.avatar_fallback>
              </.avatar>
            </.link>

            <div class="flex flex-col gap-1">
              <div class="flex items-center gap-1 text-base text-foreground">
                <.link href={~p"/org/#{@bounty.owner.handle}"} class="font-semibold hover:underline">
                  <%= @bounty.task.title %>
                </.link>
              </div>

              <div class="group flex items-center gap-2">
                <div class="font-display text-xl font-semibold text-success">
                  <%= Money.format!(@bounty.amount, @bounty.currency) %>/hr
                </div>
                <span class="text-sm text-muted-foreground">
                  · <%= @bounty.expected_hours %> hours/week
                </span>
              </div>

              <div class="mt-1 flex flex-wrap gap-2">
                <%= for tag <- @bounty.tech_stack do %>
                  <div class="ring-foreground/25 ring-1 ring-inset bg-foreground/5 text-foreground rounded-lg px-2 py-1 text-xs font-medium">
                    <%= tag %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <div class="flex flex-col items-end gap-3">
            <div class="text-right">
              <div class="text-sm text-muted-foreground">Total contract value</div>
              <div class="font-display text-lg font-semibold text-foreground">
                <%= Money.format!(
                  Decimal.mult(@bounty.amount, @bounty.expected_hours),
                  @bounty.currency
                ) %> / wk
              </div>
            </div>
            <.button phx-click="accept_contract" phx-value-org={@bounty.owner.handle} size="sm">
              <.link navigate={~p"/contracts/1337"}>
                Accept contract
              </.link>
            </.button>
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
                <%= String.first(@bounty.owner.name) %>
              </.avatar_fallback>
            </.avatar>
          </.link>

          <div class="flex flex-col gap-1">
            <div class="flex items-center gap-1 text-sm text-muted-foreground">
              <.link href={~p"/org/#{@bounty.owner.handle}"} class="font-semibold hover:underline">
                <%= @bounty.owner.name %>
              </.link>
              <.icon name="tabler-chevron-right" class="h-4 w-4" />
              <.link href={Bounty.url(@bounty)} class="hover:underline">
                <%= Bounty.path(@bounty) %>
              </.link>
            </div>

            <.link href={Bounty.url(@bounty)} class="group flex items-center gap-2">
              <div class="font-display text-xl font-semibold text-success">
                <%= Money.format!(@bounty.amount, @bounty.currency) %>
              </div>
              <div class="text-foreground group-hover:underline line-clamp-1">
                <%= @bounty.task.title %>
              </div>
            </.link>

            <div class="flex flex-wrap gap-2">
              <%= for tag <- @bounty.tech_stack do %>
                <span class="text-sm text-muted-foreground">
                  #<%= tag %>
                </span>
              <% end %>
            </div>
          </div>
        </div>
      </td>
    </tr>
    """
  end
end
