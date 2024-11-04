defmodule AlgoraWeb.Org.AnalyticsLive do
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.StatCard
  alias Algora.Bounties
  alias Algora.Money

  def mount(_params, _session, socket) do
    org_id = socket.assigns.current_org.id
    stats = Bounties.fetch_stats(org_id)
    recent_bounties = Bounties.list_bounties(owner_id: org_id, limit: 10)
    recent_activities = fetch_recent_activities()

    {:ok,
     socket
     |> assign(:stats, stats)
     |> assign(:recent_bounties, recent_bounties)
     |> assign(:recent_activities, recent_activities)}
  end

  def render(assigns) do
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
