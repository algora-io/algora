defmodule AlgoraWeb.ClaimLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Bounties.Claim
  alias Algora.Repo

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, claim} = Repo.fetch(Claim, id)

    claim = Repo.preload(claim, [:user, source: [repository: [:user]], target: [repository: [:user], bounties: [:owner]]])

    dbg(claim)
    {:ok, prize_pool} = claim.target.bounties |> Enum.map(& &1.amount) |> Money.sum()

    {:ok,
     socket
     |> assign(:page_title, "Claim Details")
     |> assign(:claim, claim)
     |> assign(:target, claim.target)
     |> assign(:source, claim.source)
     |> assign(:user, claim.user)
     |> assign(:bounties, claim.target.bounties)
     |> assign(:prize_pool, prize_pool)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto py-8 px-4">
      <div class="space-y-8">
        <%!-- Header with target issue and prize pool --%>
        <.header class="mb-8">
          <div class="space-y-2">
            <.link href={@target.url} class="text-xl font-semibold hover:underline" target="_blank">
              {@target.title}
            </.link>
            <div class="text-sm text-muted-foreground">
              {@source.repository.user.provider_login}/{@source.repository.name}#{@source.number}
            </div>
          </div>
          <:subtitle>
            <div class="mt-4 text-2xl font-bold text-success font-display">
              {Money.to_string!(@prize_pool)}
            </div>
          </:subtitle>
          <:actions>
            <.button variant="outline">
              <.icon name="tabler-clock" class="mr-2 h-4 w-4" />
              {@claim.status |> to_string() |> String.capitalize()}
            </.button>
          </:actions>
        </.header>

        <%!-- Claimant and Sponsors Cards --%>
        <div class="grid gap-8 md:grid-cols-2">
          <%!-- Claimer Info --%>
          <.card>
            <.card_header>
              <.card_title>
                <div class="flex items-center gap-2">
                  <.icon name="tabler-user" class="h-5 w-5 text-muted-foreground" /> Claimed By
                </div>
              </.card_title>
            </.card_header>
            <.card_content>
              <div class="flex items-center gap-4">
                <.avatar>
                  <.avatar_image src={@user.avatar_url} />
                  <.avatar_fallback>
                    {String.first(@user.name)}
                  </.avatar_fallback>
                </.avatar>
                <div>
                  <p class="font-medium">{@user.name}</p>
                  <p class="text-sm text-muted-foreground">@{@user.handle}</p>
                </div>
              </div>
            </.card_content>
          </.card>

          <%!-- Bounty Sponsors Card --%>
          <.card>
            <.card_header>
              <.card_title>
                <div class="flex items-center gap-2">
                  <.icon name="tabler-users" class="h-5 w-5 text-muted-foreground" /> Sponsors
                </div>
              </.card_title>
            </.card_header>
            <.card_content>
              <div class="divide-y divide-border">
                <%= for bounty <- @bounties do %>
                  <div class="flex items-center justify-between py-4">
                    <div class="flex items-center gap-4">
                      <.avatar>
                        <.avatar_image src={bounty.owner.avatar_url} />
                        <.avatar_fallback>
                          {String.first(bounty.owner.name)}
                        </.avatar_fallback>
                      </.avatar>
                      <div>
                        <p class="font-medium">{bounty.owner.name}</p>
                        <p class="text-sm text-muted-foreground">@{bounty.owner.handle}</p>
                      </div>
                    </div>
                    <.badge variant="secondary">
                      {Money.to_string!(bounty.amount)}
                    </.badge>
                  </div>
                <% end %>
              </div>
            </.card_content>
          </.card>
        </div>

        <%!-- Pull Request Details --%>
        <.card>
          <.card_header>
            <.card_title>
              <div class="flex items-center gap-2">
                <.icon name="tabler-git-pull-request" class="h-5 w-5 text-muted-foreground" />
                Pull Request
              </div>
            </.card_title>
          </.card_header>
          <.card_content>
            <div class="space-y-4">
              <.link href={@source.url} class="text-lg font-semibold hover:underline" target="_blank">
                {@source.title}
              </.link>
              <div class="text-sm text-muted-foreground">
                {@source.repository.user.provider_login}/{@source.repository.name}#{@source.number}
              </div>
              <div class="mt-4">
                {@source.description}
              </div>
            </div>
          </.card_content>
        </.card>
      </div>
    </div>
    """
  end
end
