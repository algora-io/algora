defmodule AlgoraWeb.User.DashboardLive do
  use AlgoraWeb, :live_view
  alias Algora.Bounties
  alias Algora.Money

  def mount(_params, _session, socket) do
    tech_stack = ["Rust", "Elixir"]

    socket =
      socket
      |> assign(:tech_stack, tech_stack)
      |> assign(
        :bounties,
        Bounties.list_bounties(status: :open, tech_stack: tech_stack, limit: 10)
      )
      |> assign(:achievements, fetch_achievements())
      |> assign(:events, fetch_events())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 lg:pr-96">
      <div class="p-4 pt-6 sm:p-6 md:p-8">
        <div class="space-y-8">
          <!-- Bounties Section -->
          <div class="group/card relative h-full rounded-lg border bg-card text-card-foreground">
            <div class="flex justify-between p-6 pb-4">
              <div class="flex flex-col space-y-1.5">
                <h2 class="text-2xl font-semibold leading-none tracking-tight">Bounties for you</h2>
                <p class="text-sm text-muted-foreground">Based on your tech stack</p>
              </div>
              <div>
                <.link
                  class="whitespace-pre text-sm text-muted-foreground hover:underline hover:brightness-125"
                  href="#"
                >
                  View all
                </.link>
              </div>
            </div>
            <!-- Tech Stack Input -->
            <div class="px-6">
              <div class="mt-4">
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
              </div>

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
            <!-- Bounties Table -->
            <div class="p-6">
              <div class="relative w-full overflow-auto">
                <table class="w-full caption-bottom text-sm">
                  <tbody>
                    <%= for bounty <- @bounties do %>
                      <tr class="border-b transition-colors hover:bg-muted/50">
                        <td class="p-4 align-middle">
                          <div class="flex items-center gap-4">
                            <.link href={~p"/org/#{bounty.owner.handle}"}>
                              <span class="relative flex h-14 w-14 shrink-0 overflow-hidden rounded-xl">
                                <img
                                  class="aspect-square h-full w-full"
                                  alt={bounty.owner.name}
                                  src={bounty.owner.avatar_url}
                                />
                              </span>
                            </.link>

                            <div class="flex flex-col gap-1">
                              <div class="flex items-center gap-1 text-sm text-muted-foreground">
                                <.link
                                  href={~p"/org/#{bounty.owner.handle}"}
                                  class="font-semibold hover:underline"
                                >
                                  <%= bounty.owner.name %>
                                </.link>
                                <.icon name="tabler-chevron-right" class="h-4 w-4" />
                                <.link
                                  href={"https://github.com/#{bounty.task.owner}/#{bounty.task.repo}/issues/#{bounty.task.number}"}
                                  class="hover:underline"
                                >
                                  <%= bounty.task.repo %>#<%= bounty.task.number %>
                                </.link>
                              </div>

                              <.link
                                href={"https://github.com/#{bounty.task.owner}/#{bounty.task.repo}/issues/#{bounty.task.number}"}
                                class="group flex items-center gap-2"
                              >
                                <div class="font-display text-xl font-semibold text-success">
                                  <%= Money.format!(bounty.amount, bounty.currency) %>
                                </div>
                                <div class="text-foreground group-hover:underline">
                                  <%= bounty.task.title %>
                                </div>
                              </.link>

                              <div class="flex flex-wrap gap-2">
                                <%= for tag <- bounty.tech_stack do %>
                                  <span class="text-sm text-muted-foreground">
                                    #<%= tag %>
                                  </span>
                                <% end %>
                              </div>
                            </div>
                          </div>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Activity Feed Sidebar -->
    <aside class="fixed bottom-0 right-0 top-16 hidden w-96 overflow-y-auto border-l border-border bg-muted/10 p-4 pt-6 lg:block sm:p-6 md:p-8">
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
              <%= case achievement.status do %>
                <% :completed -> %>
                  <%= achievement(%{achievement: achievement}) %>
                <% :upcoming -> %>
                  <%= achievement(%{achievement: achievement}) %>
              <% end %>
            </li>
          <% end %>
        </ol>
      </nav>
      <!-- Activity Feed Section -->
      <div class="flex items-center justify-between pt-12">
        <h2 class="text-xl font-semibold leading-none tracking-tight">Activity feed</h2>
        <.link
          class="whitespace-pre text-sm text-muted-foreground hover:underline hover:brightness-125"
          href="#"
        >
          View all
        </.link>
      </div>

      <ul class="pt-4">
        <%= for event <- @events do %>
          <li class="relative pb-8">
            <span class="absolute left-4 -bottom-6 h-5 w-0.5 bg-border"></span>
            <.event event={event} />
          </li>
        <% end %>
      </ul>
    </aside>
    """
  end

  defp format_time_ago(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :day)

    case diff do
      0 -> "today"
      1 -> "1 day ago"
      n -> "#{n} days ago"
    end
  end

  defp fetch_events() do
    [
      %{
        type: :bounty_shared,
        org: %{
          name: "Grit",
          handle: "grit",
          avatar_url: "https://avatars.githubusercontent.com/u/62914393?s=200&v=4"
        },
        count: 2,
        amount: 300,
        inserted_at: ~U[2024-10-28 20:02:22.464Z]
      },
      %{
        type: :bounty_awarded,
        org: %{name: "Algora"},
        user: %{
          name: "urbit-pilled",
          avatar_url:
            "https://console.algora.io/asset/storage/v1/object/public/images/org/clcq81tsi0001mj08ikqffh87-1715034576051"
        },
        amount: 200,
        url: "https://github.com/algora-io/tv/issues/105",
        inserted_at: ~U[2024-10-28 14:23:26.505Z]
      },
      %{
        type: :stream_started,
        user: %{
          name: "Chris Griffing",
          avatar_url: "https://avatars.githubusercontent.com/u/1195435?v=4"
        },
        url: "https://tv.algora.io/cmgriffing",
        inserted_at: ~U[2024-10-27 21:38:00.560Z]
      },
      %{
        type: :stream_started,
        user: %{
          name: "Daniel Roe",
          avatar_url: "https://avatars.githubusercontent.com/u/28706372?v=4"
        },
        url: "https://tv.algora.io/danielroe",
        inserted_at: ~U[2024-10-24 10:32:01.550Z]
      }
    ]
  end

  defp fetch_achievements() do
    [
      %{status: :completed, name: "Personalize Algora"},
      %{status: :upcoming, name: "Create Stripe account"},
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

  def event(%{event: %{type: :bounty_shared}} = assigns) do
    ~H"""
    <a class="group inline-flex" href={~p"/org/#{@event.org.handle}"}>
      <div class="relative flex space-x-3">
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div class="flex items-center gap-4">
            <div class="relative flex -space-x-1">
              <div class="relative flex-shrink-0 overflow-hidden flex h-8 w-8 items-center justify-center rounded-xl">
                <img alt={@event.org.name} src={@event.org.avatar_url} />
              </div>
            </div>
            <div class="z-10 flex gap-2">
              <span class="font-emoji text-sm sm:text-base">💎</span>
              <div class="space-y-0.5">
                <p class="text-xs text-gray-500 transition-colors dark:text-gray-200 dark:group-hover:text-white sm:text-sm">
                  <strong class="font-bold"><%= @event.org.name %></strong>
                  shared <strong class="font-bold"><%= @event.count %></strong>
                  bounties rewarding <strong class="font-bold">$<%= @event.amount %></strong>
                </p>
                <div class="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400 sm:text-sm">
                  <time datetime={@event.inserted_at}>
                    <%= format_time_ago(@event.inserted_at) %>
                  </time>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </a>
    """
  end

  def event(%{event: %{type: :bounty_awarded}} = assigns) do
    ~H"""
    <a class="group inline-flex" href={@event.url}>
      <div class="relative flex space-x-3">
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div class="flex items-center gap-4">
            <div class="relative flex -space-x-1">
              <div class="relative flex-shrink-0 overflow-hidden flex h-8 w-8 items-center justify-center rounded-xl">
                <img alt={@event.user.name} src={@event.user.avatar_url} />
              </div>
            </div>
            <div class="z-10 flex gap-2">
              <span class="font-emoji text-sm sm:text-base">💰</span>
              <div class="space-y-0.5">
                <p class="text-xs text-gray-500 transition-colors dark:text-gray-200 dark:group-hover:text-white sm:text-sm">
                  <strong class="font-bold"><%= @event.org.name %></strong>
                  awarded <strong class="font-bold"><%= @event.user.name %></strong>
                  a <strong class="font-bold">$<%= @event.amount %></strong>
                  bounty
                </p>
                <div class="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400 sm:text-sm">
                  <time datetime={@event.inserted_at}>
                    <%= format_time_ago(@event.inserted_at) %>
                  </time>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </a>
    """
  end

  def event(%{event: %{type: :stream_started}} = assigns) do
    ~H"""
    <a class="group inline-flex" href={@event.url}>
      <div class="relative flex space-x-3">
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div class="flex items-center gap-4">
            <div class="relative flex -space-x-1">
              <div class="relative flex-shrink-0 overflow-hidden flex h-8 w-8 items-center justify-center rounded-xl">
                <img alt={@event.user.name} src={@event.user.avatar_url} />
              </div>
            </div>
            <div class="z-10 flex gap-2">
              <span class="font-emoji text-sm sm:text-base">🔴</span>
              <div class="space-y-0.5">
                <p class="text-xs text-gray-500 transition-colors dark:text-gray-200 dark:group-hover:text-white sm:text-sm">
                  <strong class="font-bold"><%= @event.user.name %></strong> started streaming
                </p>
                <div class="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400 sm:text-sm">
                  <time datetime={@event.inserted_at}>
                    <%= format_time_ago(@event.inserted_at) %>
                  </time>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </a>
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
end
