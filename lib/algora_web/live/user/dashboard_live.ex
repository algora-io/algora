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
      |> assign(:view_mode, "default")
      |> assign(
        :bounties,
        Bounties.list_bounties(status: :open, tech_stack: tech_stack, limit: 20)
        |> intersperse_hourly_bounties()
      )
      |> assign(:achievements, fetch_achievements())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 lg:pr-96 bg-background text-foreground">
      <!-- Bounties Section -->
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
        <!-- Tech Stack Input -->
        <div class="px-6 pt-3">
          <.input
            id="tech-input"
            name="tech-input"
            value=""
            type="text"
            placeholder="Elixir, Phoenix, PostgreSQL, etc."
            phx-keydown="handle_tech_input"
            phx-debounce="200"
            phx-hook="ClearInput"
            class="w-full bg-background border-input"
          />
          <div class="flex flex-wrap gap-3 mt-4">
            <%= for tech <- @tech_stack do %>
              <div class="bg-success/10 text-success rounded-lg px-3 py-1.5 text-sm font-semibold flex items-center">
                <%= tech %>
                <button
                  phx-click="remove_tech"
                  phx-value-tech={tech}
                  class="ml-2 text-success hover:text-success/80"
                >
                  ×
                </button>
              </div>
            <% end %>
          </div>
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
      <!-- Achievements Section -->
      <div class="flex items-center justify-between">
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
      <div class="pt-8">
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
      %{status: :upcoming, name: "Earn $10K"},
      %{status: :upcoming, name: "Earn $50K"}
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
    dbg(mode)
    {:noreply, assign(socket, :view_mode, mode)}
  end

  defp intersperse_hourly_bounties(bounties) do
    hourly_bounties = [
      %{
        amount: Decimal.new(75),
        currency: "USD",
        task: %{title: "Full-stack Elixir engineer for livestreaming platform"},
        owner: %{
          handle: "algora",
          name: "Algora",
          avatar_url:
            "https://console.algora.io/asset/storage/v1/object/public/images/org/clcq81tsi0001mj08ikqffh87-1715034576051"
        },
        tech_stack: ["elixir", "phoenix", "membrane"],
        hourly: true
      },
      %{
        amount: Decimal.new(150),
        currency: "USD",
        task: %{title: "Rust backend engineer (contract)"},
        owner: %{
          handle: "golemcloud",
          name: "Golem Cloud",
          avatar_url:
            "https://console.algora.io/_next/image?url=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F133607167%3Fs%3D200%26v%3D4&w=1920&q=75"
        },
        tech_stack: ["rust", "wasm"],
        hourly: true
      }
    ]

    bounties
    |> Enum.zip(Stream.cycle(hourly_bounties))
    |> Enum.flat_map(fn {bounty, hourly} -> [bounty, hourly] end)
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
        <div class="flex items-center gap-4">
          <.link href={~p"/org/#{@bounty.owner.handle}"}>
            <span class="relative flex h-14 w-14 shrink-0 overflow-hidden rounded-xl">
              <img
                class="aspect-square h-full w-full"
                alt={@bounty.owner.name}
                src={@bounty.owner.avatar_url}
              />
            </span>
          </.link>

          <div class="flex flex-col gap-1">
            <div class="flex items-center gap-1 text-sm text-muted-foreground">
              <.link href={~p"/org/#{@bounty.owner.handle}"} class="font-semibold hover:underline">
                <%= @bounty.owner.name %>
              </.link>
            </div>

            <div class="group flex items-center gap-2">
              <div class="font-display text-xl font-semibold text-success">
                <%= Money.format!(@bounty.amount, @bounty.currency) %>/hr
              </div>
              <.link
                navigate={~p"/org/#{@bounty.owner.handle}"}
                class="text-foreground group-hover:underline line-clamp-1"
              >
                <%= @bounty.task.title %>
              </.link>
            </div>

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

  def default_view(assigns) do
    ~H"""
    <tr class="border-b transition-colors hover:bg-muted/10">
      <td class="p-4 align-middle">
        <div class="flex items-center gap-4">
          <.link href={~p"/org/#{@bounty.owner.handle}"}>
            <span class="relative flex h-14 w-14 shrink-0 overflow-hidden rounded-xl">
              <img
                class="aspect-square h-full w-full"
                alt={@bounty.owner.name}
                src={@bounty.owner.avatar_url}
              />
            </span>
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
