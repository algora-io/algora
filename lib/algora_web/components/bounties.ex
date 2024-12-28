defmodule AlgoraWeb.Components.Bounties do
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  def bounties(assigns) do
    ~H"""
    <div class="-mt-2 -ml-4 relative w-full overflow-auto">
      <table class="w-full caption-bottom text-sm">
        <tbody>
          <%= for ticket <- @tickets do %>
            <tr class="border-b transition-colors hover:bg-muted/10 h-10">
              <td class="p-4 py-0 align-middle">
                <div class="flex items-center gap-4">
                  <div class="font-display text-base font-semibold text-success whitespace-nowrap shrink-0">
                    {Money.to_string!(ticket.total_bounty_amount)}
                  </div>

                  <.link
                    href={ticket.url}
                    class="truncate text-sm text-foreground hover:underline max-w-[400px]"
                  >
                    {ticket.title}
                  </.link>

                  <div class="flex items-center gap-1 text-sm text-muted-foreground whitespace-nowrap shrink-0">
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

                  <div class="flex -space-x-2">
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
