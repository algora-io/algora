defmodule AlgoraWeb.User.ProfileLive do
  use AlgoraWeb, :live_view
  alias Algora.{Money, Accounts, Bounties}

  def mount(%{"handle" => handle}, _session, socket) do
    # HACK: fix
    user = Accounts.get_user_by!(handle: handle)
    user = Accounts.get_user_with_stats(user.id)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:page_title, "@#{handle}")
      |> assign(:completed_bounties, Bounties.list_bounties(limit: 10, status: :completed))
      |> assign(:reviews, fetch_reviews())

    {:ok, socket}
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
              <h1 class="text-2xl font-bold"><%= @user.name %></h1>
              <p class="text-muted-foreground">@<%= @user.handle %></p>
            </div>

            <p class="text-foreground max-w-2xl"><%= @user.bio %></p>

            <div class="flex flex-wrap gap-4">
              <%= for skill <- @user.skills do %>
                <span class="rounded-lg px-2 py-0.5 text-xs ring-1 ring-border bg-secondary">
                  <%= skill %>
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
              <%= Money.format!(@user.amount, "USD") %>
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Total Earnings</div>
        </div>
        <div class="p-6 rounded-lg bg-card border border-border">
          <div class="flex items-center gap-2 mb-2">
            <div class="text-2xl font-bold font-display">
              <%= @user.bounties %>
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Bounties Solved</div>
        </div>
        <div class="p-6 rounded-lg bg-card border border-border">
          <div class="flex items-center gap-2 mb-2">
            <div class="text-2xl font-bold font-display">
              <%= @user.projects %>
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Projects Contributed</div>
        </div>
      </div>
      <!-- Replace the entire .tabs section with this: -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Completed Bounties Column -->
        <div class="space-y-4">
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
                              <%= bounty.owner.name %>
                            </.link>
                            <.icon name="tabler-chevron-right" class="h-4 w-4" />
                            <.link
                              href={"https://github.com/#{bounty.task.owner}/#{bounty.task.repo}/issues/#{bounty.task.number}"}
                              class="hover:underline"
                            >
                              <%= bounty.task.repo %>#<%= bounty.task.number %>
                            </.link>
                          </div>

                          <.link
                            href={"https://github.com/#{bounty.task.owner}/#{bounty.task.repo}/issues/#{bounty.task.number}"}
                            class="group flex items-center gap-2"
                          >
                            <div class="font-display text-xl font-semibold text-success">
                              <%= Money.format!(bounty.amount, "USD") %>
                            </div>
                            <div class="text-foreground group-hover:underline line-clamp-1">
                              <%= bounty.task.title %>
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
        </div>
        <!-- Reviews Column -->
        <div class="space-y-4">
          <h2 class="text-lg font-semibold">Reviews</h2>
          <div class="grid gap-4">
            <%= for review <- @reviews do %>
              <div class="rounded-lg bg-card p-4 text-sm border border-border">
                <div class="flex items-center gap-1 mb-2">
                  <%= for i <- 1..5 do %>
                    <.icon
                      name="tabler-star-filled"
                      class={"w-4 h-4 #{if i <= review.stars, do: "text-warning", else: "text-muted-foreground/25"}"}
                    />
                  <% end %>
                </div>
                <p class="text-sm mb-2"><%= review.comment %></p>
                <p class="text-xs text-muted-foreground">— <%= review.company %></p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp fetch_reviews do
    [
      %{
        stars: 5,
        comment:
          "Exceptional problem-solving skills and great communication throughout the project.",
        company: "TechCorp Inc."
      },
      %{
        stars: 4,
        comment:
          "Delivered high-quality work ahead of schedule. Would definitely work with again.",
        company: "StartupXYZ"
      },
      %{
        stars: 5,
        comment: "Outstanding technical expertise and professional attitude.",
        company: "DevLabs"
      },
      %{
        stars: 5,
        comment:
          "Brilliant developer who consistently delivers exceptional results. Their attention to detail is remarkable.",
        company: "InnovateTech"
      },
      %{
        stars: 5,
        comment:
          "Excellent problem-solver with strong architectural skills. A true professional.",
        company: "CloudScale Solutions"
      },
      %{
        stars: 5,
        comment: "Outstanding collaboration and technical expertise. Exceeded all expectations.",
        company: "DataFlow Systems"
      },
      %{
        stars: 5,
        comment: "Demonstrated deep knowledge of best practices and delivered pristine code.",
        company: "CodeCraft Industries"
      },
      %{
        stars: 5,
        comment:
          "Exceptional ability to understand complex requirements and implement elegant solutions.",
        company: "Quantum Software"
      },
      %{
        stars: 5,
        comment: "Fantastic communication skills and technical prowess. A pleasure to work with.",
        company: "ByteForge Labs"
      },
      %{
        stars: 5,
        comment:
          "Delivered high-quality code with excellent documentation. Would hire again in a heartbeat.",
        company: "Alpine Technologies"
      }
    ]
  end
end
