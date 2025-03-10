defmodule AlgoraWeb.Components.Bounties do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  alias Algora.Accounts.User

  def bounties(assigns) do
    ~H"""
    <div class="relative -mx-2 -mt-2 overflow-auto">
      <ul class="divide-y divide-border">
        <%= for bounty <- @bounties do %>
          <.link href={bounty.ticket.url} class="block hover:bg-muted/50">
            <li class="flex items-center py-2 px-3">
              <div class="flex-shrink-0 mr-3">
                <.avatar class="h-8 w-8">
                  <.avatar_image src={bounty.repository.owner.avatar_url} />
                  <.avatar_fallback>
                    {Algora.Util.initials(User.handle(bounty.repository.owner))}
                  </.avatar_fallback>
                </.avatar>
              </div>

              <div class="flex-grow min-w-0 mr-4">
                <div class="flex items-center text-sm">
                  <span class="font-semibold mr-1">{bounty.repository.name}</span>
                  <span class="text-muted-foreground mr-2">#{bounty.ticket.number}</span>
                  <span class="font-display whitespace-nowrap text-sm font-semibold tabular-nums text-success mr-2">
                    {Money.to_string!(bounty.amount)}
                  </span>
                  <span class="text-foreground truncate">{bounty.ticket.title}</span>
                </div>
              </div>
            </li>
          </.link>
        <% end %>
      </ul>
    </div>
    """
  end
end
