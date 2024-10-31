defmodule AlgoraWeb.Org.DashboardLive do
  use AlgoraWeb, :live_view

  alias Algora.Bounties
  alias Algora.Money
  on_mount AlgoraWeb.Org.BountyHook

  def mount(_params, _session, socket) do
    org_id = socket.assigns.current_org.id
    stats = Bounties.fetch_stats(org_id)
    recent_bounties = Bounties.list_bounties(owner_id: org_id, limit: 10)
    recent_activities = fetch_recent_activities()

    {:ok,
     socket
     |> assign(:onboarding_completed?, false)
     |> assign(:stats, stats)
     |> assign(:recent_bounties, recent_bounties)
     |> assign(:recent_activities, recent_activities)
     |> assign(:get_started_cards, get_started_cards())
     |> assign(:tech_stack, ["Elixir", "TypeScript"])
     |> assign(:locations, ["United States", "Remote"])
     |> assign(:matches, Algora.Accounts.list_matching_devs(limit: 8, country: "US"))}
  end

  def render(assigns) do
    ~H"""
    <%= if @onboarding_completed? do %>
      <.dashboard_onboarded {assigns} />
    <% else %>
      <.dashboard_onboarding {assigns} />
    <% end %>
    """
  end

  def dashboard_onboarded(assigns) do
    ~H"""
    <div class="flex-1 space-y-4 p-4 pt-6 sm:p-6 md:p-8">
      <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <.stat_card
          title="Open Bounties"
          value={Money.format!(@stats.open_bounties_amount, @stats.currency)}
          subtext={"#{@stats.open_bounties_count} bounties"}
          href={"/org/#{@current_org.handle}/bounties?status=open"}
          icon="tabler-diamond"
        />
        <.stat_card
          title="Total Awarded"
          value={Money.format!(@stats.total_awarded, @stats.currency)}
          subtext={"#{@stats.completed_bounties_count} bounties / tips"}
          href={"/org/#{@current_org.handle}/bounties?status=completed"}
          icon="tabler-gift"
        />
        <.stat_card
          title="Solvers"
          value={@stats.solvers_count}
          subtext={"+#{@stats.solvers_diff} from last month"}
          href={"/org/#{@current_org.handle}/solvers"}
          icon="tabler-user-code"
        />
        <.stat_card
          title="Members"
          value={@stats.members_count}
          subtext=""
          href={"/org/#{@current_org.handle}/members"}
          icon="tabler-users"
        />
      </div>
      <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <.bounties_card current_org={@current_org} bounties={@recent_bounties} />
        <.activity_card activities={@recent_activities} />
      </div>
    </div>
    """
  end

  def dashboard_onboarding(assigns) do
    ~H"""
    <div class="text-white p-4 pt-6 sm:p-6 md:p-8">
      <h1 class="text-2xl font-semibold text-white mb-8">Get started</h1>

      <div class="grid grid-cols-3 gap-8 mb-12">
        <%= for card <- @get_started_cards do %>
          <div class="group flex h-full w-full max-w-md items-center justify-center">
            <div class="relative z-10 flex h-full w-full cursor-pointer items-center overflow-hidden ring-1 group-hover:ring-2 rounded-md ring-purple-400/20 p-[1.5px]">
              <div class="absolute inset-0 h-full w-full opacity-100 group-hover:opacity-100 transition-opacity animate-rotate rounded-full bg-[conic-gradient(#5D59EB_20deg,#8b5cf6_120deg)]">
              </div>
              <.link
                class="relative flex h-full w-full overflow-hidden rounded-md bg-gray-900"
                navigate={card.href}
              >
                <div class="rounded-lg p-6 relative cursor-pointer group">
                  <div class="flex items-center gap-3 mb-4">
                    <.icon
                      name={card.icon}
                      class="h-8 w-8 text-indigo-400 group-hover:text-white transition-colors"
                    />
                    <h2 class="text-xl font-display font-semibold text-indigo-300 group-hover:text-white transition-colors">
                      <%= card.title %>
                    </h2>
                  </div>
                  <%= for paragraph <- card.paragraphs do %>
                    <p class="text-base mb-2 text-gray-300 font-medium group-hover:text-gray-100 transition-colors">
                      <%= paragraph %>
                    </p>
                  <% end %>
                  <div class="absolute bottom-4 right-6 text-3xl group-hover:translate-x-2 transition-transform">
                    &rarr;
                  </div>
                </div>
              </.link>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @onboarding_completed? do %>
        <h2 class="text-3xl font-handwriting mb-6">Your matches</h2>

        <div class="flex gap-6 mb-8">
          <div class="flex items-center">
            <span class="mr-2">Tech stack:</span>
            <%= for tech <- @tech_stack do %>
              <span class="bg-gray-700 text-sm rounded-full px-3 py-1 mr-2"><%= tech %></span>
            <% end %>
          </div>

          <div class="flex items-center">
            <span class="mr-2">Location:</span>
            <%= for location <- @locations do %>
              <span class="bg-gray-700 text-sm rounded-full px-3 py-1 mr-2"><%= location %></span>
            <% end %>
          </div>
        </div>

        <div class="grid grid-cols-4 gap-6">
          <%= for match <- @matches do %>
            <div class="bg-gray-800 rounded-lg p-4 flex flex-col h-full relative">
              <div class="absolute top-2 right-2 text-xl">
                <%= match.flag %>
              </div>
              <div class="flex items-center mb-4">
                <img
                  src={match.avatar_url}
                  alt={match.name}
                  class="w-12 h-12 rounded-full mr-3 object-cover"
                />
                <div>
                  <div class="font-semibold"><%= match.name %></div>
                  <div class="text-sm text-gray-400">@<%= match.handle %></div>
                </div>
              </div>
              <div class="text-sm mb-2"><%= Enum.join(match.skills, ", ") %></div>
              <div class="text-sm mb-4 mt-auto">
                $<%= match.amount %> earned (<%= match.bounties %> bounties, <%= match.projects %> projects)
              </div>
              <button class="w-full border border-dashed border-white text-sm py-2 rounded hover:bg-gray-700 transition-colors">
                Collaborate
              </button>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_started_cards do
    [
      %{
        title: "Create bounties",
        href: ~p"/bounties/new",
        icon: "tabler-diamond",
        paragraphs: [
          "Install Algora in your GitHub repo(s), use the Algora commands in issues and pull requests, and reward bounties without leaving GitHub.",
          "You can share your bounty board with anyone and toggle bounties between private & public."
        ]
      },
      %{
        title: "Create projects",
        href: ~p"/projects/new",
        icon: "tabler-rocket",
        paragraphs: [
          "Get matched with top developers, manage contract work and make payments globally.",
          "You can share projects with anyone and pay on hourly, fixed, milestone or bounty basis."
        ]
      },
      %{
        title: "Create jobs",
        href: ~p"/jobs/new",
        icon: "tabler-briefcase",
        paragraphs: [
          "Find new teammates, manage applicants and simplify contract-to-hire.",
          "You can use your job board and ATS privately as well as publish jobs on Algora."
        ]
      }
    ]
  end

  def stat_card(assigns) do
    ~H"""
    <.link href={@href}>
      <div class="group/card relative rounded-xl border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] md:gap-8 hover:border-white/15 hover:bg-white/[4%] h-full transition-colors duration-75 hover:brightness-125">
        <div class="p-6 flex flex-row items-center justify-between space-y-0 pb-2">
          <h3 class="tracking-tight text-sm font-medium"><%= @title %></h3>
          <.icon name={@icon} class="h-6 w-6 text-gray-400" />
        </div>
        <div class="p-6 pt-0">
          <div class="text-2xl font-bold"><%= @value %></div>
          <p class="text-xs text-gray-400"><%= @subtext %></p>
        </div>
      </div>
    </.link>
    """
  end

  def bounties_card(assigns) do
    ~H"""
    <div class="group/card relative h-full rounded-xl border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] md:gap-8 overflow-hidden lg:col-span-4">
      <div class="flex justify-between">
        <div class="flex flex-col space-y-1.5 p-6">
          <h3 class="text-2xl font-semibold leading-none tracking-tight">Bounties</h3>
          <p class="text-sm text-gray-500 dark:text-gray-400">Most recently posted bounties</p>
        </div>
        <div class="p-6">
          <.link
            class="whitespace-pre text-sm text-gray-400 hover:underline hover:brightness-125"
            href={"/org/#{@current_org.handle}/bounties?status=open"}
          >
            View all
          </.link>
        </div>
      </div>
      <div class="p-6 pt-0">
        <ul role="list" class="divide-y divide-white/5">
          <%= for bounty <- @bounties do %>
            <li>
              <.link
                class="group relative flex flex-col items-start gap-x-4 gap-y-2 py-4 sm:flex-row sm:items-center"
                rel="noopener"
                href={"https://github.com/#{bounty.task.owner}/#{bounty.task.repo}/issues/#{bounty.task.number}"}
              >
                <div class="min-w-0 flex-auto">
                  <div class="flex items-center gap-x-3">
                    <div class="flex-none rounded-full p-1 bg-emerald-400/10 text-emerald-400">
                      <div class="h-2 w-2 rounded-full bg-current"></div>
                    </div>
                    <h2 class="line-clamp-2 min-w-0 text-base font-semibold leading-none text-white group-hover:underline">
                      <%= bounty.task.title %>
                    </h2>
                  </div>
                  <div class="ml-7 mt-px flex items-center gap-x-2 text-xs leading-5 text-gray-400">
                    <div class="flex items-center gap-x-2 md:hidden lg:flex">
                      <span class="truncate">tv#<%= bounty.task.number %></span>
                      <svg viewBox="0 0 2 2" class="h-0.5 w-0.5 flex-none fill-gray-400">
                        <circle cx="1" cy="1" r="1"></circle>
                      </svg>
                    </div>
                    <p class="whitespace-nowrap">
                      <%= Algora.Util.time_ago(bounty.inserted_at) %>
                    </p>
                  </div>
                </div>
                <div class="pl-6">
                  <div class="flex-none rounded-xl px-3 py-1 font-mono text-lg font-extrabold ring-1 ring-inset bg-emerald-400/5 text-emerald-400 ring-emerald-400/30">
                    <%= Money.format!(bounty.amount, bounty.currency) %>
                  </div>
                </div>
              </.link>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  def activity_card(assigns) do
    ~H"""
    <div class="group/card relative h-full rounded-xl border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] md:gap-8 overflow-hidden lg:col-span-3">
      <div class="flex flex-col space-y-1.5 p-6">
        <h3 class="text-2xl font-semibold leading-none tracking-tight">Activity</h3>
        <p class="text-sm text-gray-500 dark:text-gray-400">See what's popping</p>
      </div>
      <div class="p-6 pt-0">
        <div>
          <ul>
            <%= for activity <- @activities do %>
              <li class="relative pb-8">
                <div class="relative">
                  <span
                    class="absolute -bottom-5 left-5 -ml-px h-4 w-0.5 bg-gray-200 transition-opacity dark:bg-gray-600"
                    aria-hidden="true"
                  >
                  </span>
                  <.link class="group inline-flex" rel="noopener" href={activity.url}>
                    <div class="relative flex space-x-3">
                      <div class="flex min-w-0 flex-1 justify-between space-x-4">
                        <div class="flex items-center gap-4">
                          <span class="relative flex shrink-0 overflow-hidden rounded-full h-10 w-10">
                            <img
                              class="aspect-square h-full w-full"
                              alt={activity.user}
                              src={"https://github.com/#{activity.user}.png"}
                            />
                          </span>
                          <div class="space-y-0.5">
                            <p class="text-sm text-gray-500 transition-colors dark:text-gray-200 dark:group-hover:text-white">
                              <%= activity_text(activity) %>
                            </p>
                            <div class="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400">
                              <time><%= activity.days_ago %> days ago</time>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </.link>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  defp activity_text(%{type: :bounty_awarded, user: user, amount: amount, currency: currency}) do
    Phoenix.HTML.raw(
      "<strong class='font-bold'>Algora</strong> awarded <strong class='font-bold'>#{user}</strong> a <strong class='font-bold'>#{Money.format!(amount, currency)}</strong> bounty"
    )
  end

  defp activity_text(%{type: :pr_submitted, user: user}) do
    Phoenix.HTML.raw(
      "<strong class='font-bold'>#{user}</strong> submitted a PR that claims a bounty"
    )
  end

  defp fetch_recent_activities do
    [
      %{
        url: "https://github.com/algora-io/tv/issues/105",
        type: :bounty_awarded,
        user: "urbit-pilled",
        amount: 50,
        currency: "USD",
        days_ago: 1
      },
      %{
        url: "https://github.com/algora-io/tv/issues/104",
        type: :pr_submitted,
        user: "GauravBurande",
        days_ago: 3
      },
      %{
        url: "https://github.com/algora-io/tv/issues/103",
        type: :bounty_awarded,
        user: "gilest",
        amount: 75,
        currency: "USD",
        days_ago: 6
      },
      %{
        url: "https://github.com/algora-io/tv/issues/102",
        type: :pr_submitted,
        user: "urbit-pilled",
        days_ago: 11
      }
    ]
  end
end
