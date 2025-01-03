defmodule AlgoraWeb.Project.ViewLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User

  def mount(%{"id" => id}, _session, socket) do
    # Mock data for a single project
    project = %{
      id: id,
      title: "Build Real-time Chat Application",
      country: socket.assigns.current_country,
      tech_stack: ["Elixir", "Phoenix", "Phoenix LiveView", "PostgreSQL"],
      budget: %{type: :hourly, from: Money.new!(50, :USD), to: Money.new!(75, :USD)},
      description: "Looking for an experienced developer to build a real-time chat system...",
      posted_at: ~N[2024-03-15 10:00:00],
      client: %{
        name: "John Doe",
        avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=John",
        projects_posted: 5
      },
      step: 1,
      total_steps: 5
    }

    matching_devs =
      Accounts.list_developers(
        limit: 6,
        sort_by_country: project.country,
        sort_by_tech_stack: project.tech_stack,
        min_earnings: Money.new!(200, "USD")
      )

    {:ok,
     socket
     |> assign(:project, project)
     |> assign(:matching_devs, matching_devs)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen p-8 text-white">
      <div class="mx-auto max-w-6xl space-y-8">
        <%!-- Project Header Card (Keep existing) --%>
        <div class="bg-white/[7.5%] rounded-lg p-6">
          <div class="flex items-start justify-between gap-8">
            <div class="flex-1">
              <h1 class="font-display mb-4 text-2xl font-semibold">
                {@project.title}
              </h1>

              <div class="mb-4 flex flex-wrap gap-2">
                <%= for tech <- @project.tech_stack do %>
                  <span class="rounded-xl px-3 py-1 text-sm text-white ring-1 ring-white/20">
                    {tech}
                  </span>
                <% end %>
              </div>

              <div class="flex items-center gap-4 text-sm text-gray-400">
                <div class="flex items-center gap-1">
                  <.icon name="tabler-clock" class="h-4 w-4" />
                  Posted {Calendar.strftime(@project.posted_at, "%B %d, %Y")}
                </div>
                <div class="flex items-center gap-1">
                  <.icon name="tabler-world" class="h-4 w-4" />
                  {@project.country}
                </div>
              </div>
            </div>
            <div class="text-right">
              <div class="font-display text-3xl font-semibold text-emerald-400">
                <%= case @project.budget.type do %>
                  <% :hourly -> %>
                    ${@project.budget.from}-{@project.budget.to}/hour
                  <% :fixed -> %>
                    {Money.to_string!(@project.budget.from)}-{Money.to_string!(@project.budget.to)}
                <% end %>
              </div>
              <div class="text-sm text-gray-400">
                {String.capitalize("#{@project.budget.type}")} Rate
              </div>
            </div>
          </div>
        </div>

        <%!-- Project Tabs --%>
        <.tabs :let={builder} id="project-tabs" default="overview">
          <.tabs_list class="flex w-full space-x-1 rounded-lg bg-white/5 p-1">
            <.tabs_trigger builder={builder} value="overview" class="flex-1">
              <.icon name="tabler-layout-dashboard" class="mr-2 h-4 w-4" /> Overview
            </.tabs_trigger>
            <.tabs_trigger builder={builder} value="invitations" class="flex-1">
              <.icon name="tabler-users" class="mr-2 h-4 w-4" /> Invitations
            </.tabs_trigger>
            <.tabs_trigger builder={builder} value="documents" class="flex-1">
              <.icon name="tabler-file" class="mr-2 h-4 w-4" /> Documents
            </.tabs_trigger>
            <.tabs_trigger builder={builder} value="bounties" class="flex-1">
              <.icon name="tabler-dia" class="mr-2 h-4 w-4" /> Bounties
            </.tabs_trigger>
            <.tabs_trigger builder={builder} value="payments" class="flex-1">
              <.icon name="tabler-credit-card" class="mr-2 h-4 w-4" /> Payments
            </.tabs_trigger>
          </.tabs_list>

          <%!-- Overview Tab --%>
          <.tabs_content value="overview">
            <div class="space-y-6">
              <%!-- Project Description --%>
              <.card>
                <.card_header>
                  <.card_title>Project Description</.card_title>
                </.card_header>
                <.card_content>
                  <p class="text-gray-400">{@project.description}</p>
                </.card_content>
              </.card>

              <%!-- Matching Developers Section (Keep existing) --%>
              <div>
                <div class="mb-6 flex items-center justify-between">
                  <h2 class="text-xl font-semibold">Best Matches</h2>
                  <.button>
                    <.icon name="tabler-user-plus" class="mr-2 h-4 w-4" /> Invite Match
                  </.button>
                </div>
                <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                  <%= for dev <- @matching_devs do %>
                    <div class="bg-white/[7.5%] rounded-lg p-4">
                      <div class="flex gap-4">
                        <img src={dev.avatar_url} alt={dev.name} class="h-16 w-16 rounded-full" />
                        <div class="min-w-0 flex-1">
                          <div class="flex justify-between">
                            <div class="truncate">
                              <div class="text-lg font-semibold">{dev.name} {dev.flag}</div>
                              <div class="text-sm text-gray-400">@{User.handle(dev)}</div>
                            </div>
                            <div class="text-right">
                              <div class="text-sm text-gray-400">Earned</div>
                              <div class="font-semibold">
                                {Money.to_string!(dev.total_earned)}
                              </div>
                            </div>
                          </div>
                          <div class="mt-2 flex flex-wrap gap-2">
                            <%= for tech <- dev.tech_stack do %>
                              <span class="rounded-xl px-2 py-0.5 text-xs text-white ring-1 ring-white/20">
                                {tech}
                              </span>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </.tabs_content>

          <%!-- Invitations Tab --%>
          <.tabs_content value="invitations">
            <div class="space-y-6">
              <.card>
                <.card_header>
                  <.card_title>Invitations</.card_title>
                </.card_header>
                <.card_content>
                  <div class="py-12 text-center">
                    <.icon name="tabler-users" class="mx-auto mb-4 h-12 w-12 text-gray-400" />
                    <h3 class="mb-2 text-lg font-medium">No invitations yet</h3>
                    <p class="mb-4 text-gray-400">Start by inviting developers to your project</p>
                    <.button>
                      <.icon name="tabler-user-plus" class="mr-2 h-4 w-4" />
                      Discover & Invite Developers
                    </.button>
                  </div>
                </.card_content>
              </.card>
            </div>
          </.tabs_content>

          <%!-- Documents Tab --%>
          <.tabs_content value="documents">
            <div class="space-y-6">
              <.card>
                <.card_header>
                  <.card_title>Project Documents</.card_title>
                </.card_header>
                <.card_content>
                  <div class="py-12 text-center">
                    <.icon name="tabler-file-upload" class="mx-auto mb-4 h-12 w-12 text-gray-400" />
                    <h3 class="mb-2 text-lg font-medium">No documents uploaded</h3>
                    <p class="mb-4 text-gray-400">
                      Upload NDAs, specifications, or other project documents
                    </p>
                    <.button>
                      <.icon name="tabler-upload" class="mr-2 h-4 w-4" /> Upload Documents
                    </.button>
                  </div>
                </.card_content>
              </.card>
            </div>
          </.tabs_content>

          <%!-- Bounties Tab --%>
          <.tabs_content value="bounties">
            <div class="space-y-6">
              <.card>
                <.card_header>
                  <.card_title>Project Bounties</.card_title>
                </.card_header>
                <.card_content>
                  <div class="py-12 text-center">
                    <.icon name="tabler-dia" class="mx-auto mb-4 h-12 w-12 text-gray-400" />
                    <h3 class="mb-2 text-lg font-medium">No bounties created</h3>
                    <p class="mb-4 text-gray-400">
                      Break down your project into bounties for developers
                    </p>
                    <.button>
                      <.icon name="tabler-plus" class="mr-2 h-4 w-4" /> Create First Bounty
                    </.button>
                  </div>
                </.card_content>
              </.card>
            </div>
          </.tabs_content>

          <%!-- Payments Tab --%>
          <.tabs_content value="payments">
            <div class="space-y-6">
              <.card>
                <.card_header>
                  <.card_title>Payment Setup</.card_title>
                </.card_header>
                <.card_content>
                  <div class="py-12 text-center">
                    <.icon name="tabler-credit-card" class="mx-auto mb-4 h-12 w-12 text-gray-400" />
                    <h3 class="mb-2 text-lg font-medium">Payment method required</h3>
                    <p class="mb-4 text-gray-400">
                      Add a payment method to start working with developers
                    </p>
                    <.button>
                      <.icon name="tabler-plus" class="mr-2 h-4 w-4" /> Add Payment Method
                    </.button>
                  </div>
                </.card_content>
              </.card>
            </div>
          </.tabs_content>
        </.tabs>
      </div>
    </div>
    """
  end
end
