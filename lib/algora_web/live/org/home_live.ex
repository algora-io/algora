defmodule AlgoraWeb.Org.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Payments

  @impl true
  def mount(_params, _session, socket) do
    org = socket.assigns.current_org
    open_bounties = Bounties.list_bounties(owner_id: org.id, status: :open, limit: page_size())
    top_earners = Accounts.list_developers(org_id: org.id, limit: 10, earnings_gt: Money.zero(:USD))
    stats = Bounties.fetch_stats(org.id)
    transactions = Payments.list_hosted_transactions(org.id, limit: page_size())

    socket =
      socket
      |> assign(:org, org)
      |> assign(:page_title, org.name)
      |> assign(:open_bounties, open_bounties)
      |> assign(:transactions, transactions)
      |> assign(:top_earners, top_earners)
      |> assign(:stats, stats)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6">
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

            <div class="flex gap-4 items-center">
              <%= for {platform, icon} <- social_links(),
                      url = social_link(@org, platform),
                      not is_nil(url) do %>
                <.link href={url} target="_blank" class="text-muted-foreground hover:text-foreground">
                  <.icon name={icon} class="size-5" />
                </.link>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-6 grid grid-cols-1 gap-6 md:grid-cols-4">
        <.stat_card
          title="Open Bounties"
          value={Money.to_string!(@stats.open_bounties_amount)}
          subtext={"#{@stats.open_bounties_count} bounties"}
          navigate={~p"/org/#{@org.handle}/bounties?status=open"}
          icon="tabler-diamond"
        />
        <.stat_card
          title="Total Awarded"
          value={Money.to_string!(@stats.total_awarded_amount)}
          subtext={"#{@stats.rewarded_bounties_count} #{ngettext("bounty", "bounties", @stats.rewarded_bounties_count)} / #{@stats.rewarded_tips_count} #{ngettext("tip", "tips", @stats.rewarded_tips_count)} / #{@stats.rewarded_contracts_count} #{ngettext("contract", "contracts", @stats.rewarded_contracts_count)}"}
          navigate={~p"/org/#{@org.handle}/bounties?status=completed"}
          icon="tabler-gift"
        />
        <.stat_card
          title="Solvers"
          value={@stats.solvers_count}
          subtext={"+#{@stats.solvers_diff} from last month"}
          navigate={~p"/org/#{@org.handle}/leaderboard"}
          icon="tabler-user-code"
        />
        <.stat_card
          title="Members"
          value={@stats.members_count}
          subtext=""
          navigate={~p"/org/#{@org.handle}/team"}
          icon="tabler-users"
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
                  <tr class="h-10 border-b transition-colors hover:bg-muted/10">
                    <td class="p-4 py-0 align-middle">
                      <div class="flex items-center gap-4">
                        <div class="font-display shrink-0 whitespace-nowrap text-base font-semibold text-success">
                          {Money.to_string!(bounty.amount)}
                        </div>

                        <.link
                          href={Bounty.url(bounty)}
                          class="max-w-[400px] truncate text-sm text-foreground hover:underline"
                        >
                          {bounty.ticket.title}
                        </.link>

                        <div class="flex shrink-0 items-center gap-1 whitespace-nowrap text-sm text-muted-foreground">
                          <.icon name="tabler-chevron-right" class="h-4 w-4" />
                          <.link href={Bounty.url(bounty)} class="hover:underline">
                            {Bounty.path(bounty)}
                          </.link>
                        </div>
                      </div>
                    </td>
                  </tr>
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
                <%= for %{transaction: transaction, ticket: ticket} <- @transactions do %>
                  <tr class="h-10 border-b transition-colors hover:bg-muted/10">
                    <td class="p-4 py-0 align-middle">
                      <div class="flex items-center gap-4">
                        <div class="font-display shrink-0 whitespace-nowrap text-base font-semibold text-success">
                          {Money.to_string!(transaction.net_amount)}
                        </div>

                        <.link
                          href={
                            if ticket.repository,
                              do:
                                "https://github.com/#{ticket.repository.user.provider_login}/#{ticket.repository.name}/issues/#{ticket.number}",
                              else: ticket.url
                          }
                          class="max-w-[400px] truncate text-sm text-foreground hover:underline"
                        >
                          {ticket.title}
                        </.link>

                        <div class="flex shrink-0 items-center gap-1 whitespace-nowrap text-sm text-muted-foreground">
                          <.icon name="tabler-chevron-right" class="h-4 w-4" />
                          <.link
                            href={
                              if ticket.repository,
                                do:
                                  "https://github.com/#{ticket.repository.user.provider_login}/#{ticket.repository.name}/issues/#{ticket.number}",
                                else: ticket.url
                            }
                            class="hover:underline"
                          >
                            {Bounty.path(%{ticket: ticket})}
                          </.link>
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

      <div class="space-y-4">
        <h2 class="text-lg font-semibold">Top Earners</h2>
        <div class="rounded-xl border bg-card">
          <%= for {earner, idx} <- Enum.with_index(@top_earners) do %>
            <div class="flex items-center gap-4 border-b p-4 last:border-0">
              <div class="w-8 flex-shrink-0 text-center font-mono text-muted-foreground">
                #{idx + 1}
              </div>
              <.link navigate={User.url(earner)} class="flex flex-1 items-center gap-3">
                <.avatar class="h-8 w-8">
                  <.avatar_image src={earner.avatar_url} alt={earner.name} />
                </.avatar>
                <div>
                  <div class="font-medium">
                    {earner.name} {Algora.Misc.CountryEmojis.get(earner.country)}
                  </div>
                  <div class="text-sm text-muted-foreground">@{User.handle(earner)}</div>
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

  defp social_links do
    [
      {:website, "tabler-world"},
      {:github, "github"},
      {:twitter, "tabler-brand-x"},
      {:youtube, "tabler-brand-youtube"},
      {:twitch, "tabler-brand-twitch"},
      {:discord, "tabler-brand-discord"},
      {:slack, "tabler-brand-slack"},
      {:linkedin, "tabler-brand-linkedin"}
    ]
  end

  defp social_link(user, :github), do: if(login = user.provider_login, do: "https://github.com/#{login}")
  defp social_link(user, platform), do: Map.get(user, :"#{platform}_url")

  defp page_size, do: 5
end
