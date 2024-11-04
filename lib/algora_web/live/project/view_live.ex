defmodule AlgoraWeb.Project.ViewLive do
  use AlgoraWeb, :live_view
  alias Algora.Money
  alias Algora.Accounts

  def mount(%{"id" => id}, _session, socket) do
    # Mock data for a single project
    project = %{
      id: id,
      title: "Build Real-time Chat Application",
      country: "US",
      skills: ["Elixir", "Phoenix", "Phoenix LiveView", "PostgreSQL"],
      budget: %{type: :hourly, from: 50, to: 75},
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

    matching_devs = Accounts.list_matching_devs(country: "US", limit: 6, skills: project.skills)

    {:ok,
     socket
     |> assign(:project, project)
     |> assign(:matching_devs, matching_devs)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen text-white p-8">
      <div class="max-w-6xl mx-auto space-y-8">
        <%!-- Project Header Card (Keep existing) --%>
        <div class="bg-white/[7.5%] rounded-lg p-6">
          <div class="flex justify-between items-start gap-8">
            <div class="flex-1">
              <h1 class="text-2xl font-display font-semibold mb-4">
                <%= @project.title %>
              </h1>

              <div class="flex flex-wrap gap-2 mb-4">
                <%= for skill <- @project.skills do %>
                  <span class="text-white rounded-xl px-3 py-1 text-sm ring-1 ring-white/20">
                    <%= skill %>
                  </span>
                <% end %>
              </div>

              <div class="flex items-center gap-4 text-gray-400 text-sm">
                <div class="flex items-center gap-1">
                  <.icon name="tabler-clock" class="w-4 h-4" />
                  Posted <%= Calendar.strftime(@project.posted_at, "%B %d, %Y") %>
                </div>
                <div class="flex items-center gap-1">
                  <.icon name="tabler-world" class="w-4 h-4" />
                  <%= @project.country %>
                </div>
              </div>
            </div>
            <div class="text-right">
              <div class="text-emerald-400 font-semibold font-display text-3xl">
                <%= case @project.budget.type do %>
                  <% :hourly -> %>
                    $<%= @project.budget.from %>-<%= @project.budget.to %>/hour
                  <% :fixed -> %>
                    <%= Money.format!(@project.budget.from, "USD") %>-<%= Money.format!(
                      @project.budget.to,
                      "USD"
                    ) %>
                <% end %>
              </div>
              <div class="text-sm text-gray-400">
                <%= String.capitalize("#{@project.budget.type}") %> Rate
              </div>
            </div>
          </div>
        </div>

        <%!-- Project Tabs --%>
        <.tabs :let={builder} id="project-tabs" default="overview">
          <.tabs_list class="w-full flex space-x-1 rounded-lg bg-white/5 p-1">
            <.tabs_trigger builder={builder} value="overview" class="flex-1">
              <.icon name="tabler-layout-dashboard" class="w-4 h-4 mr-2" /> Overview
            </.tabs_trigger>
            <.tabs_trigger builder={builder} value="invitations" class="flex-1">
              <.icon name="tabler-users" class="w-4 h-4 mr-2" /> Invitations
            </.tabs_trigger>
            <.tabs_trigger builder={builder} value="documents" class="flex-1">
              <.icon name="tabler-file" class="w-4 h-4 mr-2" /> Documents
            </.tabs_trigger>
            <.tabs_trigger builder={builder} value="bounties" class="flex-1">
              <.icon name="tabler-dia" class="w-4 h-4 mr-2" /> Bounties
            </.tabs_trigger>
            <.tabs_trigger builder={builder} value="payments" class="flex-1">
              <.icon name="tabler-credit-card" class="w-4 h-4 mr-2" /> Payments
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
                  <p class="text-gray-400"><%= @project.description %></p>
                </.card_content>
              </.card>

              <%!-- Matching Developers Section (Keep existing) --%>
              <div>
                <div class="flex justify-between items-center mb-6">
                  <h2 class="text-xl font-semibold">Best Matches</h2>
                  <.button>
                    <.icon name="tabler-user-plus" class="w-4 h-4 mr-2" /> Invite Match
                  </.button>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <%= for dev <- @matching_devs do %>
                    <div class="bg-white/[7.5%] p-4 rounded-lg">
                      <div class="flex gap-4">
                        <img src={dev.avatar_url} alt={dev.name} class="w-16 h-16 rounded-full" />
                        <div class="flex-1 min-w-0">
                          <div class="flex justify-between">
                            <div class="truncate">
                              <div class="font-semibold text-lg"><%= dev.name %> <%= dev.flag %></div>
                              <div class="text-sm text-gray-400">@<%= dev.handle %></div>
                            </div>
                            <div class="text-right">
                              <div class="text-gray-400 text-sm">Earned</div>
                              <div class="font-semibold"><%= Money.format!(dev.amount, "USD") %></div>
                            </div>
                          </div>
                          <div class="mt-2 flex flex-wrap gap-2">
                            <%= for skill <- dev.skills do %>
                              <span class="text-white rounded-xl px-2 py-0.5 text-xs ring-1 ring-white/20">
                                <%= skill %>
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
                  <div class="text-center py-12">
                    <.icon name="tabler-users" class="w-12 h-12 mx-auto text-gray-400 mb-4" />
                    <h3 class="text-lg font-medium mb-2">No invitations yet</h3>
                    <p class="text-gray-400 mb-4">Start by inviting developers to your project</p>
                    <.button>
                      <.icon name="tabler-user-plus" class="w-4 h-4 mr-2" />
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
                  <div class="text-center py-12">
                    <.icon name="tabler-file-upload" class="w-12 h-12 mx-auto text-gray-400 mb-4" />
                    <h3 class="text-lg font-medium mb-2">No documents uploaded</h3>
                    <p class="text-gray-400 mb-4">
                      Upload NDAs, specifications, or other project documents
                    </p>
                    <.button>
                      <.icon name="tabler-upload" class="w-4 h-4 mr-2" /> Upload Documents
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
                  <div class="text-center py-12">
                    <.icon name="tabler-dia" class="w-12 h-12 mx-auto text-gray-400 mb-4" />
                    <h3 class="text-lg font-medium mb-2">No bounties created</h3>
                    <p class="text-gray-400 mb-4">
                      Break down your project into bounties for developers
                    </p>
                    <.button>
                      <.icon name="tabler-plus" class="w-4 h-4 mr-2" /> Create First Bounty
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
                  <div class="text-center py-12">
                    <.icon name="tabler-credit-card" class="w-12 h-12 mx-auto text-gray-400 mb-4" />
                    <h3 class="text-lg font-medium mb-2">Payment method required</h3>
                    <p class="text-gray-400 mb-4">
                      Add a payment method to start working with developers
                    </p>
                    <.button>
                      <.icon name="tabler-plus" class="w-4 h-4 mr-2" /> Add Payment Method
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
