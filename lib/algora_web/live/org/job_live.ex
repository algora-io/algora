defmodule AlgoraWeb.Org.JobLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Bounties.Bounty

  def mount(_params, _session, socket) do
    job = %{
      title: "Senior Elixir Developer for Video Processing Platform",
      description: """
      We're seeking an experienced Elixir developer to help build and scale our video processing platform. You'll work on developing high-performance video processing pipelines using FFmpeg and implementing real-time features with Phoenix LiveView.

      Key Responsibilities:
      • Design and implement scalable backend services in Elixir/Phoenix
      • Optimize video processing workflows using FFmpeg
      • Write clean, maintainable, and well-tested code
      • Collaborate with the team on architecture decisions
      • Mentor junior developers

      Requirements:
      • 5+ years of software development experience
      • Strong experience with Elixir and Phoenix Framework
      • Familiarity with FFmpeg and video processing concepts
      • Experience with PostgreSQL and database optimization
      • Knowledge of modern frontend technologies (TailwindCSS)
      • Excellent problem-solving and communication skills

      We offer competitive compensation, flexible remote work, and the opportunity to work on challenging technical problems at scale.
      """,
      tech_stack: ["Elixir", "Phoenix", "PostgreSQL", "TailwindCSS", "FFmpeg"],
      country: socket.assigns.current_country
    }

    nav_items = [
      %{
        icon: "tabler-home",
        label: "Dashboard",
        href: "#",
        active: true
      },
      %{
        icon: "tabler-diamond",
        label: "Bountes",
        href: "#",
        active: false
      },
      %{
        icon: "tabler-file",
        label: "Documents",
        href: "#",
        active: false
      },
      %{
        icon: "tabler-users",
        label: "Team",
        href: "#",
        active: false
      }
    ]

    footer_nav_items = [
      %{
        icon: "tabler-settings",
        label: "Settings",
        href: "#"
      }
    ]

    user_menu_items = [
      %{label: "My Account", href: "#", divider: true},
      %{label: "Settings", href: "#"},
      %{label: "Support", href: "#", divider: true},
      %{label: "Logout", href: "#"}
    ]

    filter_menu_items = [
      %{label: "Fulfilled", href: "#"},
      %{label: "Declined", href: "#"},
      %{label: "Refunded", href: "#"}
    ]

    time_periods = [
      %{label: "Week", value: "week"},
      %{label: "Month", value: "month"},
      %{label: "Year", value: "year"}
    ]

    matching_devs =
      Accounts.list_developers(
        limit: 5,
        sort_by_country: job.country,
        sort_by_tech_stack: job.tech_stack,
        min_earnings: Money.new!(200, "USD")
      )

    bounties = Bounties.list_bounties(limit: 8)

    {:ok,
     assign(socket,
       page_title: "Job",
       job: job,
       show_full_description: false,
       nav_items: nav_items,
       footer_nav_items: footer_nav_items,
       user_menu_items: user_menu_items,
       filter_menu_items: filter_menu_items,
       time_periods: time_periods,
       active_period: "week",
       matching_devs: matching_devs,
       bounties: bounties
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen w-full flex-col bg-muted/10" data-phx-id="m1-phx-GAPTpMFHc9kS4XZh">
      <div class="flex flex-col sm:gap-4 sm:py-4">
        <main class="grid flex-1 items-start gap-4 p-4 sm:px-6 sm:py-0 lg:grid-cols-3 xl:grid-cols-3">
          <div class="grid auto-rows-max items-start gap-4 lg:col-span-2">
            <div class="grid gap-4 sm:grid-cols-2">
              <div
                class="rounded-xl border bg-card text-card-foreground shadow sm:col-span-2"
                data-phx-id="m57-phx-GAPTpMFHc9kS4XZh"
              >
                <div class="flex flex-col space-y-1.5 p-6 pb-3">
                  <div class="flex items-start justify-between gap-4">
                    <div class="flex-1">
                      <h3 class="mb-4 text-2xl font-semibold leading-none tracking-tight">
                        {@job.title}
                      </h3>

                      <div class="mb-4 flex flex-wrap gap-2">
                        <%= for tech <- @job.tech_stack do %>
                          <span class="inline-flex items-center rounded-full border border-transparent bg-secondary px-2.5 py-0.5 text-xs font-semibold text-secondary-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2">
                            {tech}
                          </span>
                        <% end %>
                      </div>

                      <div class="flex items-center gap-4 text-sm text-muted-foreground">
                        <div class="flex items-center gap-1">
                          <.icon name="tabler-clock" class="h-4 w-4" /> Posted March 15, 2024
                        </div>
                        <div class="flex items-center gap-1">
                          <.icon name="tabler-world" class="h-4 w-4" /> {@job.country}
                        </div>
                      </div>
                    </div>
                    <%= if @job[:hourly_rate] do %>
                      <div class="text-right">
                        <div class="font-display text-3xl font-semibold text-primary">
                          {Money.to_string!(@job.hourly_rate)}/hour
                        </div>
                        <div class="text-sm text-muted-foreground">
                          Hourly Rate
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
                <div class="border-t p-6">
                  <div class="max-w-none prose prose-invert">
                    <div class="text-foreground-muted">
                      <%= if @show_full_description do %>
                        {@job.description}
                      <% else %>
                        {String.split(@job.description, "\n") |> Enum.take(3) |> Enum.join("\n")}...
                      <% end %>

                      <button
                        phx-click="toggle_description"
                        class="mt-2 text-sm font-medium text-primary hover:text-primary/80"
                      >
                        {if @show_full_description, do: "Show less", else: "See more"}
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div
              class=""
              id="tabs"
              phx-mounted="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-state=active]&quot;}],[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;active&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-target=week]&quot;}],[&quot;hide&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content:not([value=week])&quot;}],[&quot;show&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content[value=week]&quot;}]]"
              data-phx-id="m77-phx-GAPTpMFHc9kS4XZh"
            >
              <div
                class="tabs-content ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                value="week"
                data-phx-id="m93-phx-GAPTpMFHc9kS4XZh"
              >
                <div
                  class="rounded-xl border bg-card text-card-foreground shadow"
                  data-phx-id="m94-phx-GAPTpMFHc9kS4XZh"
                >
                  <div
                    class="flex flex-col space-y-1.5 p-6 px-7"
                    data-phx-id="m95-phx-GAPTpMFHc9kS4XZh"
                  >
                    <h3
                      class="text-2xl font-semibold leading-none tracking-tight"
                      data-phx-id="m96-phx-GAPTpMFHc9kS4XZh"
                    >
                      Bounties
                    </h3>
                    <p class="text-sm text-muted-foreground" data-phx-id="m97-phx-GAPTpMFHc9kS4XZh">
                      Bounties linked to your job
                    </p>
                  </div>
                  <div class="p-6 pt-0" data-phx-id="m98-phx-GAPTpMFHc9kS4XZh">
                    <table
                      class="w-full caption-bottom text-sm"
                      data-phx-id="m99-phx-GAPTpMFHc9kS4XZh"
                    >
                      <thead class="[&_tr]:border-b sr-only">
                        <tr class="border-b transition-colors data-[state=selected]:bg-muted hover:bg-muted/50">
                          <th class="h-12 px-4 text-left align-middle font-medium text-muted-foreground">
                            Ticket
                          </th>
                        </tr>
                      </thead>
                      <tbody class="[&_tr:last-child]:border-0">
                        <%= if @bounties == [] do %>
                          <tr>
                            <td colspan="5" class="p-8">
                              <div class="flex flex-col items-center space-y-3 text-center">
                                <div class="rounded-full bg-primary/10 p-3">
                                  <.icon name="tabler-plus" class="h-6 w-6 text-primary" />
                                </div>
                                <h3 class="text-lg font-semibold">No Bounties Yet</h3>
                                <p class="text-balance text-sm text-muted-foreground">
                                  Create your first bounty to start attracting developers to your job.
                                </p>
                                <.button>
                                  <.icon name="tabler-plus" class="mr-2 h-4 w-4" /> Add Bounty
                                </.button>
                              </div>
                            </td>
                          </tr>
                        <% else %>
                          <%= for bounty <- @bounties do %>
                            <tr class="h-10 border-b transition-colors hover:bg-muted/10">
                              <td class="p-4 py-0 align-middle">
                                <div class="flex items-center gap-4">
                                  <div class="font-display shrink-0 whitespace-nowrap text-base font-semibold text-success">
                                    {Money.to_string!(bounty.amount)}
                                  </div>

                                  <.link
                                    href={Bounty.url(bounty)}
                                    class="max-w-[400px] truncate text-sm text-foreground hover:underline"
                                  >
                                    {bounty.ticket.title}
                                  </.link>

                                  <div class="flex shrink-0 items-center gap-1 whitespace-nowrap text-sm text-muted-foreground">
                                    <.link
                                      navigate={User.url(bounty.owner)}
                                      class="font-semibold hover:underline"
                                    >
                                      {bounty.owner.name}
                                    </.link>
                                    <.icon name="tabler-chevron-right" class="h-4 w-4" />
                                    <.link href={Bounty.url(bounty)} class="hover:underline">
                                      {Bounty.path(bounty)}
                                    </.link>
                                  </div>
                                </div>
                              </td>
                            </tr>
                          <% end %>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="lg:col-span-1">
            <div class="mb-4 rounded-xl border bg-card text-card-foreground shadow">
              <div class="p-6">
                <div class="flex flex-col items-center space-y-3 text-center">
                  <div class="rounded-full bg-primary/10 p-3">
                    <.icon name="tabler-users-plus" class="h-6 w-6 text-primary" />
                  </div>
                  <h3 class="text-lg font-semibold">Invite Developers</h3>
                  <p class="text-sm text-muted-foreground">
                    Share this job with developers in your network or invite them directly.
                  </p>
                  <div class="flex gap-2">
                    <.button>
                      Invite Developers
                    </.button>
                    <.button variant="outline">
                      Share Link
                    </.button>
                  </div>
                </div>
              </div>
            </div>

            <%= if @matching_devs != [] do %>
              <div class="rounded-xl border bg-card text-card-foreground shadow">
                <div class="p-6">
                  <h2 class="mb-4 text-lg font-semibold leading-none tracking-tight">
                    Matching Developers
                  </h2>

                  <div class="space-y-4">
                    <%= for dev <- @matching_devs do %>
                      <div class="flex items-center gap-4 rounded-lg bg-accent/50 p-4">
                        <img src={dev.avatar_url} alt={dev.name} class="h-12 w-12 rounded-full" />
                        <div class="min-w-0 flex-grow">
                          <div class="flex items-start justify-between gap-2">
                            <div class="truncate">
                              <div class="truncate font-medium">
                                {dev.name} {dev.flag}
                              </div>
                              <div class="truncate text-sm text-muted-foreground">
                                @{User.handle(dev)}
                              </div>
                            </div>
                            <div class="shrink-0 text-right">
                              <div class="text-sm text-muted-foreground">Earned</div>
                              <div class="font-medium">
                                {Money.to_string!(dev.total_earned)}
                              </div>
                            </div>
                          </div>

                          <div class="mt-2 flex flex-wrap gap-1">
                            <%= for tech <- dev.tech_stack do %>
                              <span class="inline-flex items-center rounded-full border border-transparent bg-secondary px-2.5 py-0.5 text-xs font-semibold text-secondary-foreground transition-colors hover:bg-secondary/80 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2">
                                {tech}
                              </span>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </main>
      </div>
    </div>
    """
  end

  def handle_event("select_period", %{"period" => period}, socket) do
    {:noreply, assign(socket, active_period: period)}
  end

  def handle_event("toggle_description", _, socket) do
    {:noreply, assign(socket, show_full_description: !socket.assigns.show_full_description)}
  end
end
