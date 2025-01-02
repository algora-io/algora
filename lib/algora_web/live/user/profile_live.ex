defmodule AlgoraWeb.User.ProfileLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Bounties
  alias Algora.Reviews
  alias Algora.Reviews.Review
  alias Algora.Users

  def mount(%{"handle" => handle}, _session, socket) do
    {:ok, user} = Users.fetch_developer_by(handle: handle)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:page_title, "#{user.name}")
     |> assign(:completed_bounties, Bounties.list_bounties_awarded_to_user(user.id, limit: 10))
     |> assign(:reviews, Reviews.list_reviews(reviewee_id: user.id, limit: 10))}
  end

  def render(assigns) do
    ~H"""
    <div class="container max-w-6xl mx-auto p-6 space-y-6">
      <!-- Profile Header -->
      <div class="rounded-xl border bg-card text-card-foreground p-6">
        <div class="flex flex-col md:flex-row gap-6">
          <div class="flex-shrink-0">
            <.avatar class="h-12 w-12 md:h-16 md:w-16">
              <.avatar_image src={@user.avatar_url} alt={@user.name} />
            </.avatar>
          </div>

          <div class="flex-1 space-y-4">
            <div>
              <h1 class="text-2xl font-bold">{@user.name}</h1>
              <p class="text-muted-foreground">@{@user.handle}</p>
            </div>

            <p class="text-foreground max-w-2xl">{@user.bio}</p>

            <div class="flex flex-wrap gap-4">
              <%= for tech <- @user.tech_stack do %>
                <span class="rounded-lg px-2 py-0.5 text-xs ring-1 ring-border bg-secondary">
                  {tech}
                </span>
              <% end %>
            </div>
          </div>

          <div class="flex-shrink-0 space-y-3">
            <.button class="w-full">
              <.icon name="tabler-currency-dollar" class="w-4 h-4 mr-2" /> Pay
            </.button>
            <.button class="w-full" variant="outline">
              <.icon name="tabler-mail" class="w-4 h-4 mr-2" /> Invite
            </.button>
          </div>
        </div>
      </div>
      <!-- Stats Grid -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="p-6 rounded-lg bg-card border border-border">
          <div class="flex items-center gap-2 mb-2">
            <div class="text-2xl font-bold font-display">
              {Money.to_string!(@user.total_earned)}
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Total Earnings</div>
        </div>
        <div class="p-6 rounded-lg bg-card border border-border">
          <div class="flex items-center gap-2 mb-2">
            <div class="text-2xl font-bold font-display">
              {@user.completed_bounties_count}
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Bounties Solved</div>
        </div>
        <div class="p-6 rounded-lg bg-card border border-border">
          <div class="flex items-center gap-2 mb-2">
            <div class="text-2xl font-bold font-display">
              {@user.contributed_projects_count}
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Projects Contributed</div>
        </div>
      </div>
      <!-- Replace the entire .tabs section with this: -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Completed Bounties Column -->
        <div class="space-y-4">
          <%= if Enum.empty?(@completed_bounties) do %>
            <.card class="text-center">
              <.card_header>
                <div class="mx-auto rounded-full bg-muted p-4 mb-2">
                  <.icon name="tabler-diamond" class="w-8 h-8 text-muted-foreground" />
                </div>
                <.card_title>No bounties yet</.card_title>
                <.card_description>
                  Completed bounties will appear here once this user solves a bounty
                </.card_description>
              </.card_header>
            </.card>
          <% else %>
            <h2 class="text-lg font-semibold">Completed Bounties</h2>
            <div class="-ml-4 relative w-full overflow-auto">
              <table class="w-full caption-bottom text-sm">
                <tbody>
                  <%= for bounty <- @completed_bounties do %>
                    <tr class="border-b transition-colors hover:bg-muted/10">
                      <td class="p-4 align-middle">
                        <div class="flex items-center gap-4">
                          <.link href={~p"/org/#{bounty.owner.handle}"}>
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
                                href={~p"/org/#{bounty.owner.handle}"}
                                class="font-semibold hover:underline"
                              >
                                {bounty.owner.name}
                              </.link>
                              <.icon name="tabler-chevron-right" class="h-4 w-4" />
                              <.link
                                href={"https://github.com/#{bounty.repository.owner.login}/#{bounty.repository.name}/issues/#{bounty.ticket.number}"}
                                class="hover:underline"
                              >
                                {bounty.repository.name}#{bounty.ticket.number}
                              </.link>
                            </div>

                            <.link
                              href={"https://github.com/#{bounty.repository.owner.login}/#{bounty.repository.name}/issues/#{bounty.ticket.number}"}
                              class="group flex items-center gap-2"
                            >
                              <div class="font-display text-xl font-semibold text-success">
                                {Money.to_string!(bounty.amount)}
                              </div>
                              <div class="text-foreground group-hover:underline line-clamp-1">
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
                  <div class="mx-auto rounded-full bg-muted p-4 mb-2">
                    <.icon name="tabler-message-circle" class="w-8 h-8 text-muted-foreground" />
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
                <div class="w-full rounded-lg bg-card p-4 text-sm border border-border">
                  <div class="flex items-center gap-1 mb-2">
                    <%= for i <- 1..Review.max_rating() do %>
                      <.icon
                        name="tabler-star-filled"
                        class={"w-4 h-4 #{if i <= review.rating, do: "text-warning", else: "text-muted-foreground/25"}"}
                      />
                    <% end %>
                  </div>
                  <p class="text-sm mb-2">{review.content}</p>
                  <div class="flex items-center gap-3">
                    <.avatar class="h-8 w-8">
                      <.avatar_image src={review.reviewer.avatar_url} alt={review.reviewer.name} />
                      <.avatar_fallback>
                        {String.first(review.reviewer.name)}
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
