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
        :transactions,
        source: [repository: [:user]],
        target: [repository: [:user], bounties: [:owner]]
      ])

    case claims do
      [] ->
        raise(AlgoraWeb.NotFoundError)

      [primary_claim | _] ->
        prize_pool =
          primary_claim.target.bounties
          |> Enum.map(& &1.amount)
          |> Enum.reduce(Money.zero(:USD, no_fraction_if_integer: true), &Money.add!(&1, &2))

        debits =
          claims
          |> Enum.flat_map(& &1.transactions)
          |> Enum.filter(&(&1.type == :debit and &1.status == :succeeded))

        total_paid =
          debits
          |> Enum.map(& &1.net_amount)
          |> Enum.reduce(Money.zero(:USD, no_fraction_if_integer: true), &Money.add!(&1, &2))

        source_body_html =
          with token when is_binary(token) <- Github.TokenPool.get_token(),
               {:ok, source_body_html} <- Github.render_markdown(token, primary_claim.source.description) do
            source_body_html
          else
            _ -> primary_claim.source.description
          end

        pledges =
          primary_claim.target.bounties
          |> Enum.group_by(& &1.owner.id)
          |> Map.new(fn {owner_id, bounties} ->
            {owner_id,
             {hd(bounties).owner,
              Enum.reduce(bounties, Money.zero(:USD, no_fraction_if_integer: true), &Money.add!(&1.amount, &2))}}
          end)

        payments =
          debits
          |> Enum.group_by(& &1.user_id)
          |> Map.new(fn {user_id, debits} ->
            {user_id, Enum.reduce(debits, Money.zero(:USD, no_fraction_if_integer: true), &Money.add!(&1.net_amount, &2))}
          end)

        sponsors =
          pledges
          |> Enum.map(fn {sponsor_id, {sponsor, pledged}} ->
            paid = Map.get(payments, sponsor_id, Money.zero(:USD, no_fraction_if_integer: true))
            tipped = Money.sub!(paid, pledged)

            status =
              cond do
                Money.equal?(paid, pledged) -> :paid
                Money.positive?(tipped) -> :overpaid
                Money.positive?(paid) -> :partial
                primary_claim.status == :approved -> :pending
                true -> :none
              end

            %{
              sponsor: sponsor,
              status: status,
              pledged: pledged,
              paid: paid,
              tipped: tipped
            }
          end)
          |> Enum.sort_by(&{&1.pledged, &1.paid, &1.sponsor.name}, :desc)

        {:ok,
         socket
         |> assign(:page_title, primary_claim.source.title)
         |> assign(:claims, claims)
         |> assign(:primary_claim, primary_claim)
         |> assign(:target, primary_claim.target)
         |> assign(:source, primary_claim.source)
         |> assign(:bounties, primary_claim.target.bounties)
         |> assign(:prize_pool, prize_pool)
         |> assign(:total_paid, total_paid)
         |> assign(:source_body_html, source_body_html)
         |> assign(:sponsors, sponsors)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto py-8 px-4">
      <div class="space-y-8">
        <.header class="mb-8">
          <div class="grid gap-8 md:grid-cols-[2fr_1fr]">
            <div class="flex items-center gap-4">
              <.avatar class="h-16 w-16 rounded-full">
                <.avatar_image src={@source.repository.user.avatar_url} />
                <.avatar_fallback>
                  {String.first(@source.repository.user.provider_login)}
                </.avatar_fallback>
              </.avatar>
              <div class="space-y-2">
                <.link
                  href={@target.url}
                  class="text-xl font-semibold hover:underline"
                  target="_blank"
                >
                  {@target.title}
                </.link>
                <div class="text-sm text-muted-foreground">
                  {@source.repository.user.provider_login}/{@source.repository.name}#{@source.number}
                </div>
              </div>
            </div>
            <div class="mt-4 grid grid-cols-2 gap-8">
              <.stat_card title="Total Paid">
                <div class="text-success">
                  {Money.to_string!(@total_paid)}
                </div>
              </.stat_card>
              <.stat_card title="Prize Pool">
                <div class="text-success">
                  {Money.to_string!(@prize_pool)}
                </div>
              </.stat_card>
            </div>
          </div>
        </.header>

        <div class="grid gap-8 md:grid-cols-[2fr_1fr]">
          <div class="space-y-8">
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

          <div class="space-y-8">
            <.card>
              <.card_header>
                <.card_title>
                  Claim
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

            <.card>
              <.card_header>
                <.card_title>
                  Sponsors
                </.card_title>
              </.card_header>
              <.card_content>
                <div class="divide-y divide-border">
                  <%= for sponsor <- @sponsors do %>
                    <div class="flex items-center justify-between py-4">
                      <div class="flex items-center gap-4">
                        <.avatar>
                          <.avatar_image src={sponsor.sponsor.avatar_url} />
                          <.avatar_fallback>
                            {String.first(sponsor.sponsor.name)}
                          </.avatar_fallback>
                        </.avatar>
                        <div>
                          <p class="font-medium">{sponsor.sponsor.name}</p>
                          <p class="text-sm text-muted-foreground">@{sponsor.sponsor.handle}</p>
                        </div>
                      </div>
                      <div class="text-right">
                        <div class="text-sm font-medium">
                          <%= case sponsor.status do %>
                            <% :overpaid -> %>
                              <div class="text-success">
                                <span class="text-base font-semibold font-display tabular-nums">
                                  {Money.to_string!(Money.sub!(sponsor.paid, sponsor.tipped))}
                                </span>
                                paid
                              </div>
                              <div class="text-success">
                                <span class="text-base font-semibold font-display tabular-nums">
                                  +{Money.to_string!(sponsor.tipped)}
                                </span>
                                tip!
                              </div>
                            <% :paid -> %>
                              <div class="text-success">
                                <span class="text-base font-semibold font-display tabular-nums">
                                  {Money.to_string!(sponsor.paid)}
                                </span>
                                paid
                              </div>
                            <% :partial -> %>
                              <div class="text-success">
                                <span class="text-base font-semibold font-display tabular-nums">
                                  {Money.to_string!(sponsor.paid)}
                                </span>
                                paid
                              </div>
                              <div class="text-muted-foreground">
                                <span class="text-base font-semibold font-display tabular-nums">
                                  {Money.to_string!(Money.sub!(sponsor.pledged, sponsor.paid))}
                                </span>
                                pending
                              </div>
                            <% :pending -> %>
                              <div class="text-muted-foreground">
                                <span class="text-base font-semibold font-display tabular-nums">
                                  {Money.to_string!(sponsor.pledged)}
                                </span>
                                pending
                              </div>
                            <% :none -> %>
                              <div class="text-success">
                                <span class="text-base font-semibold font-display tabular-nums">
                                  {Money.to_string!(sponsor.pledged)}
                                </span>
                              </div>
                          <% end %>
                        </div>
                      </div>
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
