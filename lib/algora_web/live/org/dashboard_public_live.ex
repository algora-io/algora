defmodule AlgoraWeb.Org.DashboardPublicLive do
  use AlgoraWeb, :live_view
  alias Algora.{Money, Organizations, Bounties, Users}
  alias Algora.Bounties.Bounty

  def mount(%{"org_handle" => handle}, _session, socket) do
    org = Organizations.get_org_by_handle!(handle)
    open_bounties = Bounties.list_bounties(owner_id: org.id, status: :open, limit: 5)
    completed_bounties = Bounties.list_bounties(owner_id: org.id, status: :completed, limit: 5)
    top_earners = Users.list_matching_devs(limit: 10)
    stats = Bounties.fetch_stats(org.id)

    socket =
      socket
      |> assign(:org, org)
      |> assign(:page_title, org.name)
      |> assign(:open_bounties, open_bounties)
      |> assign(:completed_bounties, completed_bounties)
      |> assign(:top_earners, top_earners)
      |> assign(:stats, stats)

    {:ok, socket}
  end

  defp social_links do
    [
      {:website, "world"},
      {:github, "brand-github"},
      {:twitter, "brand-x"},
      {:youtube, "brand-youtube"},
      {:twitch, "brand-twitch"},
      {:discord, "brand-discord"},
      {:slack, "brand-slack"},
      {:linkedin, "brand-linkedin"}
    ]
  end

  defp social_link(user, :github) do
    if login = Map.get(user, :provider_login) do
      "https://github.com/#{login}"
    end
  end

  defp social_link(user, platform), do: Map.get(user, :"#{platform}_url")

  def render(assigns) do
    ~H"""
    <div class="container max-w-6xl mx-auto p-6 space-y-6">
      <!-- Org Header -->
      <div class="rounded-xl border bg-card text-card-foreground p-6">
        <div class="flex flex-col md:flex-row gap-6">
          <div class="flex-shrink-0">
            <.avatar class="h-12 w-12 md:h-16 md:w-16">
              <.avatar_image src={@org.avatar_url} alt={@org.name} />
            </.avatar>
          </div>

          <div class="flex-1 space-y-2">
            <div>
              <h1 class="text-2xl font-bold"><%= @org.name %></h1>
              <p class="mt-1 text-muted-foreground"><%= @org.bio %></p>
            </div>

            <div class="flex gap-4">
              <%= for {platform, icon} <- social_links(),
                      url = social_link(@org, platform),
                      not is_nil(url) do %>
                <.link href={url} target="_blank" class="text-muted-foreground hover:text-foreground">
                  <.icon name={"tabler-#{icon}"} class="w-5 h-5" />
                </.link>
              <% end %>
            </div>
          </div>

          <div class="flex-shrink-0">
            <.button class="w-full">
              <.icon name="tabler-briefcase" class="w-4 h-4 mr-2" /> Apply
            </.button>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mt-6">
        <.stat_card
          title="Open Bounties"
          value={Money.format!(@stats.open_bounties_amount, @stats.currency)}
          subtext={"#{@stats.open_bounties_count} bounties"}
          href={~p"/org/#{@org.handle}/bounties?status=open"}
          icon="tabler-diamond"
        />
        <.stat_card
          title="Total Awarded"
          value={Money.format!(@stats.total_awarded, @stats.currency)}
          subtext={"#{@stats.completed_bounties_count} bounties"}
          href={~p"/org/#{@org.handle}/bounties?status=completed"}
          icon="tabler-gift"
        />
        <.stat_card
          title="Solvers"
          value={@stats.solvers_count}
          subtext={"+#{@stats.solvers_diff} from last month"}
          href={~p"/org/#{@org.handle}/solvers"}
          icon="tabler-user-code"
        />
        <.stat_card
          title="Reviews"
          value={@stats.reviews_count}
          subtext="reviews"
          href={~p"/org/#{@org.handle}/reviews"}
          icon="tabler-star"
        />
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Bounties Section -->
        <div class="rounded-xl border bg-card p-6 space-y-4">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold">Open Bounties</h2>
            <.link
              href={~p"/org/#{@org.handle}/bounties?status=open"}
              class="text-sm text-muted-foreground hover:underline"
            >
              View all
            </.link>
          </div>
          <div class="-ml-4 relative w-full overflow-auto">
            <table class="w-full caption-bottom text-sm">
              <tbody>
                <%= for bounty <- @open_bounties do %>
                  <.compact_bounty_view bounty={bounty} />
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
        <!-- Completed Bounties -->
        <div class="rounded-xl border bg-card p-6 space-y-4">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold">Completed Bounties</h2>
            <.link
              href={~p"/org/#{@org.handle}/bounties?status=completed"}
              class="text-sm text-muted-foreground hover:underline"
            >
              View all
            </.link>
          </div>
          <div class="-ml-4 relative w-full overflow-auto">
            <table class="w-full caption-bottom text-sm">
              <tbody>
                <%= for bounty <- @completed_bounties do %>
                  <.compact_bounty_view bounty={bounty} />
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div class="space-y-4">
        <h2 class="text-lg font-semibold">Top Earners</h2>
        <div class="rounded-xl border bg-card">
          <%= for {earner, idx} <- Enum.with_index(@top_earners) do %>
            <div class="flex items-center gap-4 p-4 border-b last:border-0">
              <div class="flex-shrink-0 w-8 text-center font-mono text-muted-foreground">
                #<%= idx + 1 %>
              </div>
              <.link href={~p"/@/#{earner.handle}"} class="flex items-center gap-3 flex-1">
                <.avatar class="h-8 w-8">
                  <.avatar_image src={earner.avatar_url} alt={earner.name} />
                </.avatar>
                <div>
                  <div class="font-medium"><%= earner.name %> <%= earner.flag %></div>
                  <div class="text-sm text-muted-foreground">@<%= earner.handle %></div>
                </div>
              </.link>
              <div class="flex-shrink-0 font-display text-success font-medium">
                <%= Money.format!(earner.amount, "USD") %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def compact_bounty_view(assigns) do
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
            <%= @bounty.ticket.title %>
          </.link>

          <div class="flex items-center gap-1 text-sm text-muted-foreground whitespace-nowrap shrink-0">
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
end
