defmodule AlgoraWeb.User.DashboardLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Achievement
  import AlgoraWeb.Components.Bounties

  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Payments
  alias Algora.Payments.Account

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bounties.subscribe()
    end

    contracts = Algora.Contracts.list_contracts(status: :draft, contractor_id: socket.assigns.current_user.id)

    has_active_account =
      case Payments.get_account(socket.assigns.current_user) do
        %Account{payouts_enabled: true} -> true
        _ -> false
      end

    query_opts = [
      status: :open,
      limit: page_size(),
      tech_stack: socket.assigns.current_user.tech_stack,
      amount_gt: Money.new(:USD, 200)
    ]

    socket =
      socket
      |> assign(:view_mode, "compact")
      |> assign(:available_to_work, true)
      |> assign(:hourly_rate, Money.new!(50, :USD))
      |> assign(:hours_per_week, 40)
      |> assign(:contracts, contracts)
      |> assign(:has_active_account, has_active_account)
      |> assign(:query_opts, query_opts)
      |> assign_bounties()
      |> assign_achievements()

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex lg:flex-row flex-col-reverse">
      <div class="flex-1 bg-background text-foreground lg:pr-96">
        <div :if={not @has_active_account} class="relative p-4 sm:p-6 md:p-8">
          <.section>
            <.card>
              <.card_header>
                <.card_title>Connect with Stripe</.card_title>
                <.card_description>
                  Connect your Stripe account to receive payments for bounties and contracts
                </.card_description>
              </.card_header>
              <.card_content>
                <div class="flex flex-col gap-3">
                  <.button navigate={~p"/user/transactions"} class="ml-auto">
                    Connect with Stripe <.icon name="tabler-arrow-right" class="w-4 h-4 ml-2 -mr-1" />
                  </.button>
                </div>
              </.card_content>
            </.card>
          </.section>
        </div>
        <!-- Contracts section -->
        <div :if={length(@contracts) > 0} class="relative h-full p-4 sm:p-6 md:p-8">
          <div class="flex justify-between">
            <div class="flex flex-col space-y-1.5">
              <h2 class="text-2xl font-semibold leading-none tracking-tight">
                Hourly contracts
              </h2>
              <p class="text-sm text-muted-foreground">Paid out weekly</p>
            </div>
          </div>
          <div class="-ml-4">
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
        <!-- Bounties section -->
        <div :if={length(@bounties) > 0} class="relative h-full p-4 sm:p-6 md:p-8">
          <.section title="Open bounties" subtitle="Bounties for you">
            <div id="bounties-container" phx-hook="InfiniteScroll">
              <.bounties bounties={@bounties} />
              <div :if={@has_more_bounties} class="flex justify-center mt-4" id="load-more-indicator">
                <div class="animate-pulse text-muted-foreground">
                  <.icon name="tabler-loader" class="h-6 w-6 animate-spin" />
                </div>
              </div>
            </div>
          </.section>
        </div>
      </div>
      <!-- Sidebar -->
      <aside class="lg:fixed lg:top-16 lg:right-0 lg:bottom-0 lg:w-96 lg:overflow-y-auto lg:border-l lg:border-border lg:bg-background p-4 pt-6 sm:p-6 md:p-8">
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
        <div class="hidden lg:block mt-8">
          <h2 class="text-xl font-semibold leading-none tracking-tight">Achievements</h2>
          <nav class="pt-4">
            <ol role="list" class="space-y-6">
              <%= for achievement <- @achievements do %>
                <li>
                  <.achievement achievement={achievement} />
                </li>
              <% end %>
            </ol>
          </nav>
        </div>
      </aside>
    </div>
    """
  end

  defp assign_achievements(socket) do
    achievements = [
      {&personalize_status/1, "Personalize Algora", nil},
      {&setup_stripe_status/1, "Create Stripe account", ~p"/user/transactions"},
      {&earn_first_bounty_status/1, "Earn first bounty", ~p"/bounties"},
      {&share_with_friend_status/1, "Share Algora with a friend", nil},
      {&earn_10k_status/1, "Earn $10K", ~p"/bounties"}
    ]

    {achievements, _} =
      Enum.reduce_while(achievements, {[], false}, fn
        {status_fn, name, path}, {acc, found_current} ->
          status = status_fn.(socket)

          result =
            cond do
              found_current -> {acc ++ [%{status: :upcoming, name: name, path: path}], found_current}
              status == :completed -> {acc ++ [%{status: status, name: name, path: path}], false}
              true -> {acc ++ [%{status: :current, name: name, path: path}], true}
            end

          {:cont, result}
      end)

    assign(socket, :achievements, achievements)
  end

  defp personalize_status(_socket), do: :completed

  defp setup_stripe_status(socket) do
    if socket.assigns.has_active_account do
      :completed
    else
      :upcoming
    end
  end

  defp earn_first_bounty_status(socket) do
    if earned?(socket.assigns.current_user, Money.new!(0, :USD)) do
      :completed
    else
      :upcoming
    end
  end

  defp share_with_friend_status(_socket), do: :upcoming

  defp earn_10k_status(socket) do
    if earned?(socket.assigns.current_user, Money.new!(10_000, :USD)) do
      :completed
    else
      :upcoming
    end
  end

  defp earned?(user, amount) do
    cond do
      is_nil(user.total_earned) -> false
      Money.compare(user.total_earned, amount) == :lt -> false
      true -> true
    end
  end

  def handle_event("handle_tech_input", %{"key" => "Enter", "value" => tech}, socket) when byte_size(tech) > 0 do
    tech_stack = Enum.uniq([String.trim(tech) | socket.assigns.tech_stack])

    {:noreply,
     socket
     |> assign(:tech_stack, tech_stack)
     |> assign(:query_opts, Keyword.put(socket.assigns.query_opts, :tech_stack, tech_stack))
     |> assign_bounties()
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
     |> assign(:query_opts, Keyword.put(socket.assigns.query_opts, :tech_stack, tech_stack))
     |> assign_bounties()}
  end

  def handle_event("view_mode", %{"value" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, mode)}
  end

  def handle_event("view_contract", %{"org" => _org_handle}, socket) do
    {:noreply, socket}
  end

  def handle_event("load_more", _params, socket) do
    %{bounties: bounties} = socket.assigns

    more_bounties =
      Bounties.list_bounties(
        Keyword.put(socket.assigns.query_opts, :before, %{
          inserted_at: List.last(bounties).inserted_at,
          id: List.last(bounties).id
        })
      )

    {:noreply,
     socket
     |> assign(:bounties, bounties ++ more_bounties)
     |> assign(:has_more_bounties, length(more_bounties) >= page_size())}
  end

  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_bounties(socket)}
  end

  defp assign_bounties(socket) do
    bounties = Bounties.list_bounties(socket.assigns.query_opts)

    socket
    |> assign(:bounties, bounties)
    |> assign(:has_more_bounties, length(bounties) >= page_size())
  end

  defp page_size, do: 10

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
            <.link navigate={User.url(@bounty.owner)} class="font-semibold hover:underline">
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
          <.link navigate={User.url(@bounty.owner)}>
            <.avatar class="h-14 w-14 rounded-xl">
              <.avatar_image src={@bounty.owner.avatar_url} alt={@bounty.owner.name} />
              <.avatar_fallback>
                {Algora.Util.initials(@bounty.owner.name)}
              </.avatar_fallback>
            </.avatar>
          </.link>

          <div class="flex flex-col gap-1">
            <div class="flex items-center gap-1 text-sm text-muted-foreground">
              <.link navigate={User.url(@bounty.owner)} class="font-semibold hover:underline">
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
            <.link navigate={User.url(@contract.client)}>
              <.avatar class="aspect-[1200/630] h-32 w-auto rounded-lg">
                <.avatar_image src={@contract.client.og_image_url} alt={@contract.client.name} />
                <.avatar_fallback class="rounded-lg"></.avatar_fallback>
              </.avatar>
            </.link>

            <div class="flex flex-col gap-1">
              <div class="flex items-center gap-1 text-base text-foreground">
                <.link navigate={User.url(@contract.client)} class="font-semibold hover:underline">
                  {@contract.client.og_title || @contract.client.name}
                </.link>
              </div>
              <div class="line-clamp-2 text-muted-foreground">
                {@contract.client.bio}
              </div>
              <div class="group flex items-center gap-2">
                <div class="font-display text-xl font-semibold text-success">
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
              <div class="font-display text-lg font-semibold text-foreground">
                {Money.to_string!(Money.mult!(@contract.hourly_rate, @contract.hours_per_week))} / wk
              </div>
            </div>
            <.button
              navigate={~p"/org/#{@contract.client.handle}/contracts/#{@contract.id}"}
              phx-click="view_contract"
              phx-value-org={@contract.client.handle}
              size="sm"
            >
              View contract
            </.button>
          </div>
        </div>
      </td>
    </tr>
    """
  end
end
