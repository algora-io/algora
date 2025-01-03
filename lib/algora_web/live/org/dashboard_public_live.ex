defmodule AlgoraWeb.Org.DashboardPublicLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Organizations

  def mount(%{"org_handle" => handle}, _session, socket) do
    org = Organizations.get_org_by_handle!(handle)
    open_bounties = Bounties.list_bounties(owner_id: org.id, status: :open, limit: 5)
    completed_bounties = Bounties.list_bounties(owner_id: org.id, status: :paid, limit: 5)
    top_earners = Accounts.list_developers(limit: 10)
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
    <div class="container mx-auto max-w-6xl space-y-6 p-6">
      <!-- Org Header -->
      <div class="rounded-xl border bg-card p-6 text-card-foreground">
        <div class="flex flex-col gap-6 md:flex-row">
          <div class="flex-shrink-0">
            <.avatar class="h-12 w-12 md:h-16 md:w-16">
              <.avatar_image src={@org.avatar_url} alt={@org.name} />
            </.avatar>
          </div>

          <div class="flex-1 space-y-2">
            <div>
              <h1 class="text-2xl font-bold">{@org.name}</h1>
              <p class="mt-1 text-muted-foreground">{@org.bio}</p>
            </div>

            <div class="flex gap-4">
              <%= for {platform, icon} <- social_links(),
                      url = social_link(@org, platform),
                      not is_nil(url) do %>
                <.link href={url} target="_blank" class="text-muted-foreground hover:text-foreground">
                  <.icon name={"tabler-#{icon}"} class="h-5 w-5" />
                </.link>
              <% end %>
            </div>
          </div>

          <div class="flex-shrink-0">
            <.button class="w-full">
              <.icon name="tabler-briefcase" class="mr-2 h-4 w-4" /> Apply
            </.button>
          </div>
        </div>
      </div>

      <div class="mt-6 grid grid-cols-1 gap-6 md:grid-cols-4">
        <.stat_card
          title="Open Bounties"
          value={Money.to_string!(@stats.open_bounties_amount)}
          subtext={"#{@stats.open_bounties_count} bounties"}
          href={~p"/org/#{@org.handle}/bounties?status=open"}
          icon="tabler-diamond"
        />
        <.stat_card
          title="Total Awarded"
          value={Money.to_string!(@stats.total_awarded)}
          subtext={"#{@stats.completed_bounties_count} bounties"}
          href={~p"/org/#{@org.handle}/bounties?status=completed"}
          icon="tabler-gift"
        />
        <.stat_card
          title="Solvers"
          value={@stats.solvers_count}
          subtext={"+#{@stats.solvers_diff} from last month"}
          href="#"
          icon="tabler-user-code"
        />
        <.stat_card
          title="Reviews"
          value={@stats.reviews_count}
          subtext="reviews"
          href="#"
          icon="tabler-star"
        />
      </div>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <!-- Bounties Section -->
        <div class="space-y-4 rounded-xl border bg-card p-6">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold">Open Bounties</h2>
            <.link
              href={~p"/org/#{@org.handle}/bounties?status=open"}
              class="text-sm text-muted-foreground hover:underline"
            >
              View all
            </.link>
          </div>
          <div class="relative -ml-4 w-full overflow-auto">
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
        <div class="space-y-4 rounded-xl border bg-card p-6">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold">Completed Bounties</h2>
            <.link
              href={~p"/org/#{@org.handle}/bounties?status=completed"}
              class="text-sm text-muted-foreground hover:underline"
            >
              View all
            </.link>
          </div>
          <div class="relative -ml-4 w-full overflow-auto">
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
            <div class="flex items-center gap-4 border-b p-4 last:border-0">
              <div class="w-8 flex-shrink-0 text-center font-mono text-muted-foreground">
                #{idx + 1}
              </div>
              <.link href={~p"/@/#{earner.handle}"} class="flex flex-1 items-center gap-3">
                <.avatar class="h-8 w-8">
                  <.avatar_image src={earner.avatar_url} alt={earner.name} />
                </.avatar>
                <div>
                  <div class="font-medium">{earner.name} {earner.flag}</div>
                  <div class="text-sm text-muted-foreground">@{earner.handle}</div>
                </div>
              </.link>
              <div class="font-display flex-shrink-0 font-medium text-success">
                {Money.to_string!(earner.total_earned)}
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
    <tr class="h-10 border-b transition-colors hover:bg-muted/10">
      <td class="p-4 py-0 align-middle">
        <div class="flex items-center gap-4">
          <div class="font-display shrink-0 whitespace-nowrap text-base font-semibold text-success">
            {Money.to_string!(@bounty.amount)}
          </div>

          <.link
            href={Bounty.url(@bounty)}
            class="max-w-[400px] truncate text-sm text-foreground hover:underline"
          >
            {@bounty.ticket.title}
          </.link>

          <div class="flex shrink-0 items-center gap-1 whitespace-nowrap text-sm text-muted-foreground">
            <.icon name="tabler-chevron-right" class="h-4 w-4" />
            <.link href={Bounty.url(@bounty)} class="hover:underline">
              {Bounty.path(@bounty)}
            </.link>
          </div>
        </div>
      </td>
    </tr>
    """
  end
end
