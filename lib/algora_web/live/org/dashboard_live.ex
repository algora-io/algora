defmodule AlgoraWeb.Org.DashboardLive do
  use AlgoraWeb, :live_view

  on_mount AlgoraWeb.Org.BountyHook

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       stats: fetch_stats(),
       recent_bounties: fetch_recent_bounties(),
       recent_activities: fetch_recent_activities()
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 space-y-4 p-4 pt-6 sm:p-6 md:p-8">
      <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <%= for stat <- @stats do %>
          <.stat_card {stat} />
        <% end %>
      </div>
      <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <.bounties_card bounties={@recent_bounties} />
        <.activity_card activities={@recent_activities} />
      </div>
    </div>
    """
  end

  def stat_card(assigns) do
    ~H"""
    <.link href={@href}>
      <div class="group/card relative rounded-xl border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] md:gap-8 hover:border-white/15 hover:bg-white/[4%] h-full transition-colors duration-75 hover:brightness-125">
        <div class="p-6 flex flex-row items-center justify-between space-y-0 pb-2">
          <h3 class="tracking-tight text-sm font-medium"><%= @title %></h3>
          <svg class="h-6 w-6 text-gray-400">
            <%= @icon %>
          </svg>
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
            href="/org/algora/bounties?status=open"
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
                href={"https://github.com/algora-io/tv/issues/#{bounty.issue_number}"}
              >
                <div class="min-w-0 flex-auto">
                  <div class="flex items-center gap-x-3">
                    <div class="flex-none rounded-full p-1 bg-green-400/10 text-green-400">
                      <div class="h-2 w-2 rounded-full bg-current"></div>
                    </div>
                    <h2 class="line-clamp-2 min-w-0 text-base font-semibold leading-none text-white group-hover:underline">
                      <%= bounty.title %>
                    </h2>
                  </div>
                  <div class="ml-7 mt-px flex items-center gap-x-2 text-xs leading-5 text-gray-400">
                    <div class="flex items-center gap-x-2 md:hidden lg:flex">
                      <span class="truncate">tv#<%= bounty.issue_number %></span>
                      <svg viewBox="0 0 2 2" class="h-0.5 w-0.5 flex-none fill-gray-400">
                        <circle cx="1" cy="1" r="1"></circle>
                      </svg>
                    </div>
                    <p class="whitespace-nowrap"><%= bounty.days_ago %> days ago</p>
                  </div>
                </div>
                <div class="pl-6">
                  <div class="flex-none rounded-xl px-3 py-1 font-mono text-lg font-extrabold ring-1 ring-inset bg-green-400/5 text-green-400 ring-green-400/30">
                    $<%= bounty.amount %>
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

  defp activity_text(%{type: :bounty_awarded, user: user, amount: amount}) do
    Phoenix.HTML.raw(
      "<strong class='font-bold'>Algora</strong> awarded <strong class='font-bold'>#{user}</strong> a <strong class='font-bold'>$#{amount}</strong> bounty"
    )
  end

  defp activity_text(%{type: :pr_submitted, user: user}) do
    Phoenix.HTML.raw(
      "<strong class='font-bold'>#{user}</strong> submitted a PR that claims a bounty"
    )
  end

  defp fetch_stats do
    [
      %{
        title: "Open Bounties",
        value: "$800",
        subtext: "7 bounties",
        icon: bounty_icon(),
        href: "/org/algora/bounties?status=open"
      },
      %{
        title: "Total Awarded",
        value: "$1,750",
        subtext: "12 bounties / 0 tips",
        icon: award_icon(),
        href: "/org/algora/bounties?status=completed"
      },
      %{
        title: "Solvers",
        value: "8",
        subtext: "+4 from last month",
        icon: solver_icon(),
        href: "/org/algora/leaderboard"
      },
      %{
        title: "Members",
        value: "2",
        subtext: "",
        icon: member_icon(),
        href: "/org/algora/members"
      }
    ]
  end

  defp fetch_recent_bounties do
    [
      %{title: "Add livestream clipping feature", amount: 200, issue_number: 105, days_ago: 22},
      %{title: "Add OAuth flow for YouTube", amount: 50, issue_number: 104, days_ago: 22},
      %{
        title: "Add unmute overlay for autoplayed muted videos",
        amount: 25,
        issue_number: 102,
        days_ago: 24
      },
      %{
        title: "Redirect to original page after login",
        amount: 25,
        issue_number: 101,
        days_ago: 24
      }
    ]
  end

  defp fetch_recent_activities do
    [
      %{
        url: "https://github.com/algora-io/tv/issues/105",
        type: :bounty_awarded,
        user: "urbit-pilled",
        amount: 50,
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

  defp bounty_icon do
    ~S(<path d="M6 5h12l3 5l-8.5 9.5a.7 .7 0 0 1 -1 0l-8.5 -9.5l3 -5"></path><path d="M10 12l-2 -2.2l.6 -1"></path>)
  end

  defp award_icon do
    ~S(<path d="M3 8m0 1a1 1 0 0 1 1 -1h16a1 1 0 0 1 1 1v2a1 1 0 0 1 -1 1h-16a1 1 0 0 1 -1 -1z"></path><path d="M12 8l0 13"></path><path d="M19 12v7a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-7"></path><path d="M7.5 8a2.5 2.5 0 0 1 0 -5a4.8 8 0 0 1 4.5 5a4.8 8 0 0 1 4.5 -5a2.5 2.5 0 0 1 0 5"></path>)
  end

  defp solver_icon do
    ~S(<path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0"></path><path d="M6 21v-2a4 4 0 0 1 4 -4h3.5"></path><path d="M20 21l2 -2l-2 -2"></path><path d="M17 17l-2 2l2 2"></path>)
  end

  defp member_icon do
    ~S(<path d="M9 7m-4 0a4 4 0 1 0 8 0a4 4 0 1 0 -8 0"></path><path d="M3 21v-2a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v2"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path><path d="M21 21v-2a4 4 0 0 0 -3 -3.85"></path>)
  end
end
