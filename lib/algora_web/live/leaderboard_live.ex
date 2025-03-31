defmodule AlgoraWeb.LeaderboardLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User

  def mount(_params, _session, socket) do
    top_earners = Accounts.list_developers(earnings_gt: Money.zero(:USD))

    {:ok,
     socket
     |> assign(:page_title, "Leaderboard")
     |> assign(:top_earners, top_earners)}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6">
      <div class="space-y-1">
        <h1 class="text-2xl font-bold"></h1>
        <p class="text-muted-foreground"></p>
      </div>

      <.card>
        <.card_header>
          <.card_title>Leaderboard</.card_title>
          <.card_description>
            Top contributors ranked by earnings from bounties, tips, and contracts
          </.card_description>
        </.card_header>
        <.card_content>
          <div class="-mx-6 overflow-x-auto">
            <div class="inline-block min-w-full py-2 align-middle">
              <table class="min-w-full divide-y divide-border">
                <thead>
                  <tr>
                    <th scope="col" class="px-6 py-3.5 text-left text-sm font-semibold">Rank</th>
                    <th scope="col" class="px-6 py-3.5 text-left text-sm font-semibold">
                      Contributor
                    </th>
                    <th scope="col" class="px-6 py-3.5 text-left text-sm font-semibold">
                      Total Earned
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-border">
                  <tr :for={{earner, idx} <- Enum.with_index(@top_earners)}>
                    <td class="whitespace-nowrap px-6 py-4">
                      <div class="font-mono text-muted-foreground">#{idx + 1}</div>
                    </td>
                    <td class="whitespace-nowrap px-6 py-4">
                      <div class="flex items-center gap-3">
                        <.avatar>
                          <.avatar_image src={earner.avatar_url} />
                          <.avatar_fallback>
                            {Algora.Util.initials(User.handle(earner))}
                          </.avatar_fallback>
                        </.avatar>
                        <div>
                          <div class="font-medium">
                            {earner.name} {Algora.Misc.CountryEmojis.get(earner.country)}
                          </div>
                          <div class="text-sm text-muted-foreground">@{User.handle(earner)}</div>
                        </div>
                      </div>
                    </td>
                    <td class="whitespace-nowrap px-6 py-4">
                      <div class="font-display font-medium text-success">
                        {Money.to_string!(earner.total_earned)}
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </.card_content>
      </.card>
    </div>
    """
  end
end
