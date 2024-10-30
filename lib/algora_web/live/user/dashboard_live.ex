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
    <main class="lg:pr-96">
      <div class="p-4 pt-6 sm:p-6 md:p-8">
        <div class="max-w-4xl mx-auto">
          <header class="flex items-center justify-between">
            <h2 class="font-display text-2xl/7 font-semibold text-white">Bounties for you</h2>
            <a href="#" class="text-sm/6 font-semibold text-indigo-400">View all</a>
          </header>
          <div
            data-state="active"
            data-orientation="horizontal"
            role="tabpanel"
            aria-labelledby="radix-:r0:-trigger-bounties"
            id="radix-:r0:-content-bounties"
            tabindex="0"
            class="mt-2 ring-offset-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800"
            style="animation-duration: 0s;"
          >
            <div class="w-full">
              <div>
                <div class="mt-4">
                  <input
                    type="text"
                    placeholder="Elixir, Phoenix, PostgreSQL, etc."
                    phx-keydown="handle_tech_input"
                    phx-debounce="200"
                    class="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>

                <div class="flex flex-wrap gap-3 mt-4">
                  <%= for tech <- @tech_stack do %>
                    <div class="bg-indigo-900 text-indigo-200 rounded-lg px-2.5 py-1.5 text-sm font-semibold flex items-center">
                      <%= tech %>
                      <button
                        phx-click="remove_tech"
                        phx-value-tech={tech}
                        class="ml-2 text-indigo-300 hover:text-indigo-100"
                      >
                        ×
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>
              <div class="scrollbar-thin w-full overflow-auto">
                <table class="w-full caption-bottom text-sm">
                  <thead class="[&amp;_tr]:border-b hidden">
                    <tr class="border-b transition-colors data-[state=selected]:bg-gray-100 dark:hover:bg-gray-800/50 dark:data-[state=selected]:bg-gray-800 hover:bg-transparent">
                      <th class="h-12 px-4 text-left align-middle font-medium text-gray-500 dark:text-gray-400 [&amp;:has([role=checkbox])]:pr-0">
                      </th>
                      <th class="h-12 px-4 text-left align-middle font-medium text-gray-500 dark:text-gray-400 [&amp;:has([role=checkbox])]:pr-0 pl-[1rem] md:pl-[5.5rem]">
                      </th>
                    </tr>
                  </thead>
                  <tbody class="[&amp;_tr:last-child]:border-0">
                    <%= for bounty <- @bounties do %>
                      <tr class="border-b transition-colors data-[state=selected]:bg-gray-100 dark:data-[state=selected]:bg-gray-800">
                        <td class="p-4 pl-0 align-middle [&amp;:has([role=checkbox])]:pr-0 w-full py-6">
                          <div class="relative flex w-full max-w-[calc(100vw-44px)] items-center gap-4">
                            <a href={~p"/org/#{bounty.owner.handle}"}>
                              <span class="relative shrink-0 overflow-hidden flex h-14 w-14 items-center justify-center rounded-xl">
                                <img
                                  class="aspect-square h-full w-full"
                                  alt={bounty.owner.name}
                                  src={bounty.owner.avatar_url}
                                />
                              </span>
                            </a>
                            <div class="w-full truncate">
                              <div class="flex items-center gap-1 whitespace-nowrap pt-px font-mono text-sm leading-none text-white/70 transition-colors md:text-base">
                                <a
                                  class="font-bold hover:text-white/80 hover:underline"
                                  href={~p"/org/#{bounty.owner.handle}"}
                                >
                                  <%= bounty.owner.name %>
                                </a>
                                <svg
                                  xmlns="http://www.w3.org/2000/svg"
                                  width="24"
                                  height="24"
                                  viewBox="0 0 24 24"
                                  fill="none"
                                  stroke="currentColor"
                                  stroke-width="2"
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  class="h-3 w-3 text-white/50 transition-colors"
                                  aria-hidden="true"
                                >
                                  <path d="M9 6l6 6l-6 6"></path>
                                </svg>
                                <a
                                  class="group font-medium hover:text-white/80 hover:underline"
                                  rel="noopener"
                                  href="https://github.com/SigNoz/signoz/issues/6028"
                                >
                                  <span class="hidden md:inline"><%= bounty.task.owner %>/</span><%= bounty.task.repo %><span class="hidden text-white/40 group-hover:text-white/60 md:inline">#<%= bounty.task.number %></span>
                                </a>
                              </div>
                              <a
                                rel="noopener"
                                class="group mt-1.5 flex max-w-[16rem] items-center gap-2 truncate whitespace-nowrap text-sm text-white/90 transition-colors hover:text-white md:-mt-0.5 md:max-w-2xl md:truncate md:text-base"
                                href="https://github.com/SigNoz/signoz/issues/6028"
                              >
                                <div>
                                  <div class="font-display text-base font-semibold text-emerald-300/90 transition-colors group-hover:text-emerald-300 md:text-xl">
                                    <%= Money.format!(bounty.amount, bounty.currency) %>
                                  </div>
                                </div>
                                <div class="truncate group-hover:underline">
                                  <%= bounty.task.title %>
                                </div>
                              </a>
                              <ul class="mt-2 flex flex-wrap items-center gap-1.5 md:mt-0.5">
                                <%= for tag <- bounty.tech_stack do %>
                                  <li class="flex text-sm leading-none tracking-wide transition-colors text-indigo-300/90 group-hover:text-indigo-300">
                                    #<%= tag %>
                                  </li>
                                <% end %>
                              </ul>
                            </div>
                          </div>
                        </td>
                        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
                          <div class="flex flex-row-reverse justify-center">
                            <%= if false do %>
                              <.link rel="noopener" href={bounty.url}>
                                <span class="relative shrink-0 overflow-hidden -ml-2 flex h-10 w-10 items-center justify-center rounded-full ring-4 ring-gray-800">
                                  <span class="flex h-full w-full items-center justify-center dark:bg-gray-800 rounded-full bg-gray-800">
                                    +3
                                  </span>
                                </span>
                              </.link>
                            <% end %>
                            <%= for attempter <- [] do %>
                              <.link rel="noopener" href={attempter.url}>
                                <span class="relative shrink-0 overflow-hidden -ml-2 flex h-10 w-10 items-center justify-center rounded-full bg-gray-800 ring-4 ring-gray-800">
                                  <img
                                    class="aspect-square h-full w-full"
                                    alt={attempter.name}
                                    src={attempter.avatar_url}
                                  />
                                </span>
                              </.link>
                            <% end %>
                          </div>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
          <div
            data-state="inactive"
            data-orientation="horizontal"
            role="tabpanel"
            aria-labelledby="radix-:r0:-trigger-orgs"
            hidden=""
            id="radix-:r0:-content-orgs"
            tabindex="0"
            class="mt-2 ring-offset-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800"
          >
          </div>
          <div
            data-state="inactive"
            data-orientation="horizontal"
            role="tabpanel"
            aria-labelledby="radix-:r0:-trigger-rewarded"
            hidden=""
            id="radix-:r0:-content-rewarded"
            tabindex="0"
            class="mt-2 ring-offset-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800"
          >
          </div>
          <div
            data-state="inactive"
            data-orientation="horizontal"
            role="tabpanel"
            aria-labelledby="radix-:r0:-trigger-community"
            hidden=""
            id="radix-:r0:-content-community"
            tabindex="0"
            class="mt-2 ring-offset-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800"
          >
          </div>
        </div>
      </div>
    </main>
    <!-- Activity feed -->
    <aside class="bg-black/10 lg:fixed lg:bottom-0 lg:right-0 lg:top-16 lg:w-96 lg:overflow-y-auto lg:border-l lg:border-white/5 p-4 pt-6 sm:p-6 md:p-8">
      <header class="flex items-center justify-between">
        <h2 class="font-display text-xl/7 font-semibold text-white">Achievements</h2>
        <a href="#" class="text-sm/6 font-semibold text-indigo-400">View all</a>
      </header>
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

      <header class="flex items-center justify-between pt-12">
        <h2 class="font-display text-xl/7 font-semibold text-white">Activity feed</h2>
        <a href="#" class="text-sm/6 font-semibold text-indigo-400">View all</a>
      </header>
      <ul class="pt-4">
        <%= for event <- @events do %>
          <li class="relative pb-8">
            <div>
              <div class="relative">
                <span
                  class="absolute -bottom-6 left-4 h-5 w-0.5 bg-gray-200 transition-opacity dark:bg-gray-600 opacity-100"
                  aria-hidden="true"
                >
                </span>
                <.event event={event} />
              </div>
            </div>
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
    <a href="#" class="group">
      <span class="flex items-start">
        <span class="relative flex h-5 w-5 flex-shrink-0 items-center justify-center">
          <svg
            class="h-full w-full text-emerald-400 group-hover:text-emerald-300"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
            data-slot="icon"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
              clip-rule="evenodd"
            />
          </svg>
        </span>
        <span class="ml-3 text-sm font-medium text-emerald-400 group-hover:text-gray-300">
          <%= @achievement.name %>
        </span>
      </span>
    </a>
    """
  end

  def achievement(%{achievement: %{status: :upcoming}} = assigns) do
    ~H"""
    <a href="#" class="group">
      <div class="flex items-start">
        <div
          class="relative flex h-5 w-5 flex-shrink-0 items-center justify-center"
          aria-hidden="true"
        >
          <div class="h-2 w-2 rounded-full bg-gray-600 group-hover:bg-gray-500"></div>
        </div>
        <p class="ml-3 text-sm font-medium text-gray-400 group-hover:text-gray-300">
          <%= @achievement.name %>
        </p>
      </div>
    </a>
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
     |> assign(:bounties, Bounties.list_bounties(tech_stack: tech_stack, limit: 10))}
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
