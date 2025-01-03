defmodule AlgoraWeb.Components.Bounties do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  alias Algora.Accounts.User

  def bounties(assigns) do
    ~H"""
    <div class="relative -mx-2 -mt-2 overflow-auto">
      <table class="min-w-full divide-y divide-border">
        <thead>
          <tr>
            <th class="px-2 py-2 pl-2 text-left text-sm font-medium sm:px-6">Amount</th>
            <th class="max-w-[300px] px-2 py-2 text-left text-sm font-medium sm:px-6">Title</th>
            <th class="px-2 py-2 text-left text-sm font-medium sm:px-6">Issue</th>
            <th class="px-2 py-2 pr-2 text-right text-sm font-medium sm:px-6">Sponsors</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-border">
          <%= for ticket <- @tickets do %>
            <tr class="hover:bg-muted/50">
              <td class="px-2 py-2 pl-2 text-left sm:px-6">
                <div class="font-display whitespace-nowrap text-sm font-semibold tabular-nums text-success sm:text-xl">
                  {Money.to_string!(ticket.total_bounty_amount)}
                </div>
              </td>
              <td class="px-2 py-2 sm:px-6">
                <.link
                  href={ticket.url}
                  class="block min-w-40 text-sm text-foreground hover:underline"
                >
                  <span class="line-clamp-2">{ticket.title}</span>
                </.link>
              </td>
              <td class="px-2 py-2 sm:px-6">
                <div class="flex items-center gap-1 whitespace-nowrap text-sm text-muted-foreground">
                  <.link href={ticket.url} class="hover:underline">
                    <span class="mr-1 font-semibold">{ticket.repository.name}</span>#{ticket.number}
                  </.link>
                </div>
              </td>
              <td class="px-2 py-2 pr-2 sm:px-6">
                <div class="flex justify-end -space-x-2">
                  <%= for bounty <- Enum.take(ticket.top_bounties, 3) do %>
                    <.link navigate={User.url(bounty.owner)}>
                      <.avatar class="h-8 w-8">
                        <.avatar_image src={bounty.owner.avatar_url} />
                        <.avatar_fallback>
                          {String.slice(User.handle(bounty.owner), 0, 2)}
                        </.avatar_fallback>
                      </.avatar>
                    </.link>
                  <% end %>
                  <%= if ticket.bounty_count > 3 do %>
                    <div class="flex h-8 w-8 items-center justify-center rounded-full bg-muted text-xs font-medium ring-2 ring-background">
                      +{ticket.bounty_count - 3}
                    </div>
                  <% end %>
                </div>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
