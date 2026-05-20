defmodule AlgoraWeb.Components.Bounties do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  alias Algora.Accounts.User
  alias Algora.Bounties.Bounty

  def bounties(assigns) do
    ~H"""
    <div
      id="bounty-buckets"
      phx-hook="BountyBuckets"
      data-storage-key="algora:bounty-preferences:v1"
      class="space-y-6"
    >
      <section data-bucket="favorite" class="hidden space-y-2">
        <div class="flex items-center gap-2 px-1">
          <.icon name="tabler-star-filled" class="h-4 w-4 text-amber-400" />
          <h3 class="text-sm font-semibold text-foreground">Favorites</h3>
        </div>
        <div class="relative -mx-2 overflow-auto scrollbar-thin">
          <ul data-bucket-list="favorite" class="divide-y divide-border rounded-lg border border-border/60">
          </ul>
        </div>
      </section>

      <section data-bucket="remaining" class="space-y-2">
        <div class="flex items-center gap-2 px-1">
          <.icon name="tabler-list" class="h-4 w-4 text-muted-foreground" />
          <h3 class="text-sm font-semibold text-foreground">Remaining</h3>
        </div>
        <div class="relative -mx-2 overflow-auto scrollbar-thin">
          <ul data-bucket-list="remaining" class="divide-y divide-border rounded-lg border border-border/60">
            <%= for bounty <- @bounties do %>
              <li data-bounty-id={bounty.id} class="flex items-center gap-3 px-3 py-2 hover:bg-muted/50">
                <div class="flex-shrink-0">
                  <.avatar class="h-8 w-8">
                    <.avatar_image src={bounty.repository.owner.avatar_url || bounty.owner.avatar_url} />
                    <.avatar_fallback>
                      {Algora.Util.initials(User.handle(bounty.repository.owner || bounty.owner))}
                    </.avatar_fallback>
                  </.avatar>
                </div>

                <.link href={Bounty.url(bounty)} class="min-w-0 flex-1">
                  <div class="flex items-center text-sm min-w-0">
                    <span class="font-semibold mr-1 truncate">
                      {bounty.repository.owner.name || bounty.owner.name}
                    </span>
                    <span :if={bounty.ticket.number} class="text-muted-foreground mr-2 shrink-0">
                      #{bounty.ticket.number}
                    </span>
                    <span class="font-display whitespace-nowrap text-sm font-semibold tabular-nums text-success mr-2 shrink-0">
                      {Money.to_string!(bounty.amount)}
                    </span>
                    <span class="text-foreground truncate">{bounty.ticket.title}</span>
                  </div>
                </.link>

                <div class="flex shrink-0 items-center gap-2">
                  <button
                    type="button"
                    data-bounty-action="favorite"
                    class="inline-flex items-center rounded-md border border-border px-2 py-1 text-xs font-medium text-muted-foreground transition hover:bg-accent hover:text-foreground"
                    aria-label="Toggle favorite bounty"
                  >
                    <span data-favorite-label>Favorite</span>
                  </button>
                  <button
                    type="button"
                    data-bounty-action="ignore"
                    class="inline-flex items-center rounded-md border border-border px-2 py-1 text-xs font-medium text-muted-foreground transition hover:bg-accent hover:text-foreground"
                    aria-label="Toggle ignored bounty"
                  >
                    <span data-ignore-label>Ignore</span>
                  </button>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      </section>

      <section data-bucket="ignored" class="hidden space-y-2">
        <div class="flex items-center gap-2 px-1">
          <.icon name="tabler-eye-off" class="h-4 w-4 text-muted-foreground" />
          <h3 class="text-sm font-semibold text-foreground">Ignored</h3>
        </div>
        <div class="relative -mx-2 overflow-auto scrollbar-thin">
          <ul data-bucket-list="ignored" class="divide-y divide-border rounded-lg border border-border/60">
          </ul>
        </div>
      </section>
    </div>
    """
  end
end
