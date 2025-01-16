defmodule AlgoraWeb.ClaimLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Query

  alias Algora.Bounties.Claim
  alias Algora.Github
  alias Algora.Repo

  @impl true
  def mount(%{"group_id" => group_id}, _session, socket) do
    claims =
      from(c in Claim, where: c.group_id == ^group_id)
      |> order_by(desc: :group_share)
      |> Repo.all()
      |> Repo.preload([
        :user,
        source: [repository: [:user]],
        target: [repository: [:user], bounties: [:owner]]
      ])

    [primary_claim | _] = claims

    {:ok, prize_pool} = primary_claim.target.bounties |> Enum.map(& &1.amount) |> Money.sum()

    source_body_html =
      with token when is_binary(token) <- Github.TokenPool.get_token(),
           {:ok, source_body_html} <- Github.render_markdown(token, primary_claim.source.description) do
        source_body_html
      else
        _ -> primary_claim.source.description
      end

    {:ok,
     socket
     |> assign(:page_title, primary_claim.source.title)
     |> assign(:claims, claims)
     |> assign(:primary_claim, primary_claim)
     |> assign(:target, primary_claim.target)
     |> assign(:source, primary_claim.source)
     |> assign(:bounties, primary_claim.target.bounties)
     |> assign(:prize_pool, prize_pool)
     |> assign(:source_body_html, source_body_html)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto py-8 px-4">
      <div class="space-y-8">
        <%!-- Header with target issue and prize pool --%>
        <.header class="mb-8">
          <div class="flex items-center gap-4">
            <.avatar class="h-16 w-16 rounded-full">
              <.avatar_image src={@source.repository.user.avatar_url} />
              <.avatar_fallback>
                {String.first(@source.repository.user.provider_login)}
              </.avatar_fallback>
            </.avatar>
            <div class="space-y-2">
              <.link href={@target.url} class="text-xl font-semibold hover:underline" target="_blank">
                {@target.title}
              </.link>
              <div class="text-sm text-muted-foreground">
                {@source.repository.user.provider_login}/{@source.repository.name}#{@source.number}
              </div>
            </div>
          </div>
          <:actions>
            <div class="mt-4 text-2xl font-bold text-success font-display">
              {Money.to_string!(@prize_pool)}
            </div>
          </:actions>
        </.header>

        <%!-- New grid layout with different column widths --%>
        <div class="grid gap-8 md:grid-cols-[2fr_1fr]">
          <%!-- Combined Claim Details Card --%>
          <div class="space-y-8">
            <%!-- Claimer Info --%>
            <.card>
              <.card_header>
                <div class="grid grid-cols-1 sm:grid-cols-3">
                  <%= for claim <- @claims do %>
                    <div class="flex items-center gap-4">
                      <.avatar>
                        <.avatar_image src={claim.user.avatar_url} />
                        <.avatar_fallback>{String.first(claim.user.name)}</.avatar_fallback>
                      </.avatar>
                      <div>
                        <p class="font-medium">{claim.user.name}</p>
                        <p class="text-sm text-muted-foreground">@{claim.user.handle}</p>
                      </div>
                    </div>
                  <% end %>
                </div>
              </.card_header>
              <.card_content>
                <div class="space-y-6">
                  <%!-- Pull Request Details --%>
                  <div class="space-y-4">
                    <.link
                      href={@source.url}
                      class="text-lg font-semibold hover:underline"
                      target="_blank"
                    >
                      {@source.title}
                    </.link>
                    <div class="text-sm text-muted-foreground">
                      {@source.repository.user.provider_login}/{@source.repository.name}#{@source.number}
                    </div>
                    <div class="mt-4 prose dark:prose-invert">
                      {Phoenix.HTML.raw(@source_body_html)}
                    </div>
                  </div>
                </div>
              </.card_content>
            </.card>
          </div>

          <%!-- Right Column: Claim Metadata + Sponsors --%>
          <div class="space-y-8">
            <%!-- Claim Metadata Card --%>
            <.card>
              <.card_header>
                <.card_title>
                  <div class="flex items-center gap-2">
                    <.icon name="tabler-info-circle" class="h-5 w-5 text-muted-foreground" />
                    Claim Info
                  </div>
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="space-y-2">
                  <div class="flex justify-between text-sm">
                    <span class="text-muted-foreground">Status</span>
                    <span>{@primary_claim.status |> to_string() |> String.capitalize()}</span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span class="text-muted-foreground">Submitted</span>
                    <span>{Calendar.strftime(@primary_claim.inserted_at, "%B %d, %Y")}</span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span class="text-muted-foreground">Last Updated</span>
                    <span>{Calendar.strftime(@primary_claim.updated_at, "%B %d, %Y")}</span>
                  </div>
                </div>
              </.card_content>
            </.card>

            <%!-- Sponsors Card --%>
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
                  <%= for bounty <- Enum.sort_by(@bounties, &{&1.amount, &1.inserted_at}, :desc) do %>
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
                      <.badge variant="success" class="font-display">
                        {Money.to_string!(bounty.amount)}
                      </.badge>
                    </div>
                  <% end %>
                </div>
              </.card_content>
            </.card>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
