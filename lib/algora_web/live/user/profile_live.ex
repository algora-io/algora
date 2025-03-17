defmodule AlgoraWeb.User.ProfileLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Reviews
  alias Algora.Reviews.Review

  def mount(%{"handle" => handle}, _session, socket) do
    {:ok, user} = Accounts.fetch_developer_by(handle: handle)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:page_title, "#{user.name}")
     |> assign(:completed_bounties, Bounties.list_bounties_awarded_to_user(user.id, limit: 10))
     |> assign(:reviews, Reviews.list_reviews(reviewee_id: user.id, limit: 10))}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-6xl space-y-6 p-6">
      <!-- Profile Header -->
      <div class="rounded-xl border bg-card p-6 text-card-foreground">
        <div class="flex flex-col gap-6 md:flex-row">
          <div class="flex-shrink-0">
            <.avatar class="h-12 w-12 md:h-16 md:w-16">
              <.avatar_image src={@user.avatar_url} alt={@user.name} />
            </.avatar>
          </div>

          <div class="flex-1 space-y-4">
            <div>
              <h1 class="text-2xl font-bold">{@user.name}</h1>
              <p class="text-muted-foreground">@{User.handle(@user)}</p>
            </div>

            <p class="max-w-2xl text-foreground">{@user.bio}</p>

            <div class="flex flex-wrap gap-4">
              <%= for tech <- @user.tech_stack do %>
                <span class="rounded-lg bg-secondary px-2 py-0.5 text-xs ring-1 ring-border">
                  {tech}
                </span>
              <% end %>
            </div>
          </div>

          <div class="flex-shrink-0 space-y-3">
            <.button class="w-full">
              <.icon name="tabler-currency-dollar" class="mr-2 h-4 w-4" /> Pay
            </.button>
            <.button class="w-full" variant="outline">
              <.icon name="tabler-mail" class="mr-2 h-4 w-4" /> Invite
            </.button>
          </div>
        </div>
      </div>
      <!-- Stats Grid -->
      <div class="grid grid-cols-1 gap-6 md:grid-cols-3">
        <div class="rounded-lg border border-border bg-card p-6">
          <div class="mb-2 flex items-center gap-2">
            <div class="font-display text-2xl font-bold">
              {Money.to_string!(@user.total_earned)}
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Total Earnings</div>
        </div>
        <div class="rounded-lg border border-border bg-card p-6">
          <div class="mb-2 flex items-center gap-2">
            <div class="font-display text-2xl font-bold">
              {@user.completed_bounties_count}
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Bounties Solved</div>
        </div>
        <div class="rounded-lg border border-border bg-card p-6">
          <div class="mb-2 flex items-center gap-2">
            <div class="font-display text-2xl font-bold">
              {@user.contributed_projects_count}
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Projects Contributed</div>
        </div>
      </div>
      <!-- Replace the entire .tabs section with this: -->
      <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
        <!-- Completed Bounties Column -->
        <div class="space-y-4">
          <%= if Enum.empty?(@completed_bounties) do %>
            <.card class="text-center">
              <.card_header>
                <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                  <.icon name="tabler-diamond" class="h-8 w-8 text-muted-foreground" />
                </div>
                <.card_title>No bounties yet</.card_title>
                <.card_description>
                  Completed bounties will appear here once this user solves a bounty
                </.card_description>
              </.card_header>
            </.card>
          <% else %>
            <h2 class="text-lg font-semibold">Completed Bounties</h2>
            <div class="relative -ml-4 w-full overflow-auto">
              <table class="w-full caption-bottom text-sm">
                <tbody>
                  <%= for bounty <- @completed_bounties do %>
                    <tr class="border-b transition-colors hover:bg-muted/10">
                      <td class="p-4 align-middle">
                        <div class="flex items-center gap-4">
                          <.link navigate={User.url(bounty.owner)}>
                            <span class="relative flex h-14 w-14 shrink-0 overflow-hidden rounded-xl">
                              <img
                                class="aspect-square h-full w-full"
                                alt={bounty.owner.name}
                                src={bounty.owner.avatar_url}
                              />
                            </span>
                          </.link>

                          <div class="flex flex-col gap-1">
                            <div class="flex items-center gap-1 text-sm text-muted-foreground">
                              <.link
                                navigate={User.url(bounty.owner)}
                                class="font-semibold hover:underline"
                              >
                                {bounty.owner.name}
                              </.link>
                              <.icon name="tabler-chevron-right" class="h-4 w-4" />
                              <.link
                                href={"https://github.com/#{bounty.repository.owner.provider_login}/#{bounty.repository.name}/issues/#{bounty.ticket.number}"}
                                class="hover:underline"
                              >
                                {bounty.repository.name}#{bounty.ticket.number}
                              </.link>
                            </div>

                            <.link
                              href={"https://github.com/#{bounty.repository.owner.provider_login}/#{bounty.repository.name}/issues/#{bounty.ticket.number}"}
                              class="group flex items-center gap-2"
                            >
                              <div class="font-display text-xl font-semibold text-success">
                                {Money.to_string!(bounty.amount)}
                              </div>
                              <div class="line-clamp-1 text-foreground group-hover:underline">
                                {bounty.ticket.title}
                              </div>
                            </.link>
                          </div>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
        <!-- Reviews Column -->
        <div class="space-y-4">
          <div class="grid gap-4">
            <%= if Enum.empty?(@reviews) do %>
              <.card class="text-center">
                <.card_header>
                  <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                    <.icon name="tabler-message-circle" class="h-8 w-8 text-muted-foreground" />
                  </div>
                  <.card_title>No reviews yet</.card_title>
                  <.card_description>
                    Reviews will appear here once this user receives feedback
                  </.card_description>
                </.card_header>
              </.card>
            <% else %>
              <h2 class="text-lg font-semibold">Reviews</h2>
              <%= for review <- @reviews do %>
                <div class="w-full rounded-lg border border-border bg-card p-4 text-sm">
                  <div class="mb-2 flex items-center gap-1">
                    <%= for i <- 1..Review.max_rating() do %>
                      <.icon
                        name="tabler-star-filled"
                        class={"#{if i <= review.rating, do: "text-foreground", else: "text-muted-foreground/25"} h-4 w-4"}
                      />
                    <% end %>
                  </div>
                  <p class="mb-2 text-sm">{review.content}</p>
                  <div class="flex items-center gap-3">
                    <.avatar class="h-8 w-8">
                      <.avatar_image src={review.reviewer.avatar_url} alt={review.reviewer.name} />
                      <.avatar_fallback>
                        {Algora.Util.initials(review.reviewer.name)}
                      </.avatar_fallback>
                    </.avatar>
                    <div class="flex flex-col">
                      <p class="text-sm font-medium">{review.reviewer.name}</p>
                      <p class="text-xs text-muted-foreground">
                        {review.organization.name}
                      </p>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
