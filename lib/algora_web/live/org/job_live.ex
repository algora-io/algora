defmodule AlgoraWeb.Org.JobLive do
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Money

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
      country: "US"
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
      Accounts.list_matching_devs(
        limit: 5,
        country: job.country,
        skills: job.tech_stack
      )

    bounties = Bounties.list_bounties(%{limit: 8})

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
                class="rounded-xl bg-card text-card-foreground shadow sm:col-span-2 border"
                data-phx-id="m57-phx-GAPTpMFHc9kS4XZh"
              >
                <div class="flex p-6 pb-3 flex-col space-y-1.5">
                  <div class="flex justify-between items-start gap-4">
                    <div class="flex-1">
                      <h3 class="tracking-tight font-semibold leading-none text-2xl mb-4">
                        <%= @job.title %>
                      </h3>

                      <div class="flex flex-wrap gap-2 mb-4">
                        <%= for tech <- @job.tech_stack do %>
                          <span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-secondary text-secondary-foreground">
                            <%= tech %>
                          </span>
                        <% end %>
                      </div>

                      <div class="flex items-center gap-4 text-muted-foreground text-sm">
                        <div class="flex items-center gap-1">
                          <.icon name="tabler-clock" class="w-4 h-4" /> Posted March 15, 2024
                        </div>
                        <div class="flex items-center gap-1">
                          <.icon name="tabler-world" class="w-4 h-4" /> <%= @job.country %>
                        </div>
                      </div>
                    </div>
                    <%= if @job[:hourly_rate] do %>
                      <div class="text-right">
                        <div class="text-primary font-semibold font-display text-3xl">
                          <%= Money.format!(@job.hourly_rate, "USD") %>/hour
                        </div>
                        <div class="text-sm text-muted-foreground">
                          Hourly Rate
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
                <div class="border-t p-6">
                  <div class="prose prose-invert max-w-none">
                    <div class="whitespace-pre-line text-foreground-muted -my-12">
                      <%= if @show_full_description do %>
                        <%= @job.description %>
                      <% else %>
                        <%= String.split(@job.description, "\n") |> Enum.take(3) |> Enum.join("\n") %>...
                      <% end %>

                      <button
                        phx-click="toggle_description"
                        class="mt-2 text-primary hover:text-primary/80 text-sm font-medium"
                      >
                        <%= if @show_full_description, do: "Show less", else: "See more" %>
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
              <%!-- <div class="mb-2 flex items-center">
                <div
                  class="inline-flex p-1 rounded-md bg-muted text-muted-foreground items-center justify-center h-10"
                  data-phx-id="m78-phx-GAPTpMFHc9kS4XZh"
                >
                  <%= for period <- @time_periods do %>
                    <button
                      class="inline-flex px-3 py-1.5 rounded-sm ring-offset-background transition-all whitespace-nowrap items-center justify-center font-medium text-sm disabled:pointer-events-none disabled:opacity-50 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 data-[state=active]:bg-background data-[state=active]:shadow-sm data-[state=active]:text-foreground tabs-trigger"
                      data-target={period.value}
                      data-state={if @active_period == period.value, do: "active", else: ""}
                      phx-click="select_period"
                      phx-value-period={period.value}
                    >
                      <%= period.label %>
                    </button>
                  <% end %>
                </div>
                <div class="ml-auto flex items-center gap-2">
                  <div class="relative inline-block group" data-phx-id="m82-phx-GAPTpMFHc9kS4XZh">
                    <div
                      class="dropdown-menu-trigger peer"
                      data-state="closed"
                      phx-click="[[&quot;toggle_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;open&quot;,&quot;closed&quot;]}]]"
                      phx-click-away="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;closed&quot;]}]]"
                      data-phx-id="m83-phx-GAPTpMFHc9kS4XZh"
                    >
                      <button
                        class="inline-flex px-3 rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm gap-1 text-sm h-7 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border"
                        data-phx-id="m84-phx-GAPTpMFHc9kS4XZh"
                      >
                        <.icon name="tabler-filter" class="h-3.5 w-3.5" />
                        <span class="sr-only sm:not-sr-only"> Filter </span>
                      </button>
                    </div>
                    <div
                      class="z-50 animate-in peer-data-[state=closed]:fade-out-0 peer-data-[state=open]:fade-in-0 peer-data-[state=closed]:zoom-out-95 peer-data-[state=open]:zoom-in-95 peer-data-[side=bottom]:slide-in-from-top-2 peer-data-[side=left]:slide-in-from-right-2 peer-data-[side=right]:slide-in-from-left-2 peer-data-[side=top]:slide-in-from-bottom-2 absolute peer-data-[state=closed]:hidden top-full mt-2 right-0"
                      data-phx-id="m85-phx-GAPTpMFHc9kS4XZh"
                    >
                      <div class="">
                        <div
                          class="min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md top-0 left-full"
                          data-phx-id="m86-phx-GAPTpMFHc9kS4XZh"
                        >
                          <%= for item <- @filter_menu_items do %>
                            <div class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none">
                              <%= item.label %>
                            </div>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </div>
                  <button
                    class="inline-flex px-3 rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm gap-1 text-sm h-7 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border"
                    data-phx-id="m92-phx-GAPTpMFHc9kS4XZh"
                  >
                    <.icon name="tabler-file-export" class="h-3.5 w-3.5" />
                    <span class="sr-only sm:not-sr-only"> Export </span>
                  </button>
                </div>
              </div> --%>
              <div
                class="ring-offset-background focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 tabs-content"
                value="week"
                data-phx-id="m93-phx-GAPTpMFHc9kS4XZh"
              >
                <div
                  class="rounded-xl bg-card text-card-foreground shadow border"
                  data-phx-id="m94-phx-GAPTpMFHc9kS4XZh"
                >
                  <div
                    class="flex p-6 px-7 flex-col space-y-1.5"
                    data-phx-id="m95-phx-GAPTpMFHc9kS4XZh"
                  >
                    <h3
                      class="tracking-tight font-semibold leading-none text-2xl"
                      data-phx-id="m96-phx-GAPTpMFHc9kS4XZh"
                    >
                      Bounties
                    </h3>
                    <p class="text-muted-foreground text-sm" data-phx-id="m97-phx-GAPTpMFHc9kS4XZh">
                      Bounties linked to your job
                    </p>
                  </div>
                  <div class="p-6 pt-0" data-phx-id="m98-phx-GAPTpMFHc9kS4XZh">
                    <table
                      class="text-sm w-full caption-bottom"
                      data-phx-id="m99-phx-GAPTpMFHc9kS4XZh"
                    >
                      <thead class="[&_tr]:border-b">
                        <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted">
                          <th class="px-4 text-muted-foreground text-left align-middle font-medium h-12">
                            Task
                          </th>
                          <th class="hidden px-4 text-muted-foreground text-left align-middle font-medium h-12 sm:table-cell">
                            Owner
                          </th>
                          <th class="hidden px-4 text-muted-foreground text-left align-middle font-medium h-12 sm:table-cell">
                            Tech Stack
                          </th>
                          <th class="hidden px-4 text-muted-foreground text-left align-middle font-medium h-12 md:table-cell">
                            Posted
                          </th>
                          <th class="px-4 text-muted-foreground text-right align-middle font-medium h-12">
                            Bounty
                          </th>
                        </tr>
                      </thead>
                      <tbody class="[&_tr:last-child]:border-0">
                        <%= if @bounties == [] do %>
                          <tr>
                            <td colspan="5" class="p-8">
                              <div class="flex flex-col items-center text-center space-y-3">
                                <div class="rounded-full bg-primary/10 p-3">
                                  <.icon name="tabler-plus" class="w-6 h-6 text-primary" />
                                </div>
                                <h3 class="font-semibold text-lg">No Bounties Yet</h3>
                                <p class="text-sm text-muted-foreground text-balance">
                                  Create your first bounty to start attracting developers to your job.
                                </p>
                                <.button>
                                  <.icon name="tabler-plus" class="w-4 h-4 mr-2" /> Add Bounty
                                </.button>
                              </div>
                            </td>
                          </tr>
                        <% else %>
                          <%= for bounty <- @bounties do %>
                            <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted">
                              <td class="p-4 align-middle">
                                <div class="font-medium"><%= bounty.task.title %></div>
                                <div class="hidden text-sm text-muted-foreground md:inline">
                                  <%= bounty.task.owner %>/<%= bounty.task.repo %> #<%= bounty.task.number %>
                                </div>
                              </td>
                              <td class="hidden p-4 align-middle sm:table-cell">
                                <div class="flex items-center gap-2">
                                  <img src={bounty.owner.avatar_url} class="h-6 w-6 rounded-full" />
                                  <%= bounty.owner.name %>
                                </div>
                              </td>
                              <td class="hidden p-4 align-middle sm:table-cell">
                                <div class="flex flex-wrap gap-1">
                                  <%= for tech <- bounty.tech_stack || [] do %>
                                    <div class="inline-flex px-2.5 py-0.5 rounded-full border-transparent bg-secondary text-secondary-foreground text-xs">
                                      <%= tech %>
                                    </div>
                                  <% end %>
                                </div>
                              </td>
                              <td class="hidden p-4 align-middle md:table-cell">
                                <%= Calendar.strftime(bounty.inserted_at, "%Y-%m-%d") %>
                              </td>
                              <td class="p-4 text-right align-middle">
                                <%= Money.format!(bounty.amount, bounty.currency) %>
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
            <div class="rounded-xl bg-card text-card-foreground shadow border mb-4">
              <div class="p-6">
                <div class="flex flex-col items-center text-center space-y-3">
                  <div class="rounded-full bg-primary/10 p-3">
                    <.icon name="tabler-users-plus" class="w-6 h-6 text-primary" />
                  </div>
                  <h3 class="font-semibold text-lg">Invite Developers</h3>
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
              <div class="rounded-xl bg-card text-card-foreground shadow border">
                <div class="p-6">
                  <h2 class="tracking-tight font-semibold leading-none text-lg mb-4">
                    Matching Developers
                  </h2>

                  <div class="space-y-4">
                    <%= for dev <- @matching_devs do %>
                      <div class="flex items-center gap-4 p-4 rounded-lg bg-accent/50">
                        <img src={dev.avatar_url} alt={dev.name} class="w-12 h-12 rounded-full" />
                        <div class="flex-grow min-w-0">
                          <div class="flex justify-between items-start gap-2">
                            <div class="truncate">
                              <div class="font-medium truncate">
                                <%= dev.name %> <%= dev.flag %>
                              </div>
                              <div class="text-sm text-muted-foreground truncate">
                                @<%= dev.handle %>
                              </div>
                            </div>
                            <div class="text-right shrink-0">
                              <div class="text-sm text-muted-foreground">Earned</div>
                              <div class="font-medium">
                                <%= Money.format!(dev.amount, "USD") %>
                              </div>
                            </div>
                          </div>

                          <div class="mt-2 flex flex-wrap gap-1">
                            <%= for skill <- dev.skills do %>
                              <span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80">
                                <%= skill %>
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
