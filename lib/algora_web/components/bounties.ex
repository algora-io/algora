defmodule AlgoraWeb.Components.Bounties do
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  def bounties(assigns) do
    ~H"""
    <div class="-mt-2 -mx-2 relative overflow-auto">
      <table class="min-w-full divide-y divide-border">
        <thead>
          <tr>
            <th class="px-6 pl-2 py-2 text-left text-sm font-medium max-w-[300px]">Title</th>
            <th class="px-6 py-2 text-left text-sm font-medium">Issue</th>
            <th class="px-6 py-2 text-center text-sm font-medium">Sponsors</th>
            <th class="px-6 pr-2 py-2 text-right text-sm font-medium">Amount</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-border">
          <%= for ticket <- @tickets do %>
            <tr class="hover:bg-muted/50">
              <td class="px-6 pl-2 py-2">
                <.link href={ticket.url} class="block text-sm text-foreground hover:underline">
                  {ticket.title}
                </.link>
              </td>
              <td class="px-6 py-2">
                <div class="flex items-center gap-1 text-sm text-muted-foreground whitespace-nowrap">
                  <.link
                    :if={ticket.repository.owner.login}
                    href={"https://github.com/#{ticket.repository.owner.login}"}
                    class="font-semibold hover:underline"
                  >
                    {ticket.repository.owner.login}
                  </.link>
                  <.icon name="tabler-chevron-right" class="h-4 w-4" />
                  <.link href={ticket.url} class="hover:underline">
                    {ticket.repository.name}#{ticket.number}
                  </.link>
                </div>
              </td>
              <td class="px-6 py-2">
                <div class="flex -space-x-2 justify-center">
                  <%= for bounty <- Enum.take(ticket.top_bounties, 3) do %>
                    <.link href={"https://github.com/#{bounty.owner.provider_login}"}>
                      <.avatar class="h-8 w-8">
                        <.avatar_image src={bounty.owner.avatar_url} />
                        <.avatar_fallback>
                          {String.slice(bounty.owner.handle, 0, 2)}
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
              <td class="px-6 pr-2 py-2 text-right">
                <div class="font-display text-xl font-semibold text-success whitespace-nowrap tabular-nums">
                  {Money.to_string!(ticket.total_bounty_amount)}
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
