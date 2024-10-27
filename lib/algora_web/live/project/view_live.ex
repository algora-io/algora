defmodule AlgoraWeb.Project.ViewLive do
  use AlgoraWeb, :live_view
  alias Algora.Money

  def mount(%{"id" => id}, _session, socket) do
    # Mock data for a single project (in production, you'd fetch this from your database)
    project = %{
      id: id,
      title: "Build Real-time Chat Application",
      country: "US",
      skills: ["Elixir", "Phoenix", "Phoenix LiveView", "PostgreSQL"],
      scope: %{size: "medium", duration: "medium", experience: "intermediate"},
      budget: %{type: :hourly, from: 50, to: 75},
      description: """
      Looking for an experienced developer to build a real-time chat system. The system should include:

      • User authentication and authorization
      • Real-time message delivery
      • Message history and search
      • File sharing capabilities
      • Read receipts and typing indicators
      • Group chat functionality

      The ideal candidate should have strong experience with Elixir/Phoenix and WebSocket implementations.
      """,
      posted_at: ~N[2024-03-15 10:00:00],
      client: %{
        name: "John Doe",
        avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=John",
        projects_posted: 5,
        member_since: ~D[2023-01-15],
        last_active: ~N[2024-03-20 15:30:00]
      }
    }

    {:ok, assign(socket, project: project)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white p-8">
      <div class="max-w-4xl mx-auto">
        <div class="flex items-center gap-3 text-gray-400 mb-6">
          <.link navigate={~p"/projects"} class="hover:text-white transition">
            <.icon name="tabler-arrow-left" class="w-5 h-5" />
          </.link>
          <div class="text-sm">Back to projects</div>
        </div>

        <div class="space-y-8">
          <%!-- Header Section --%>
          <div class="bg-white/[7.5%] rounded-lg p-6">
            <div class="flex justify-between items-start gap-8">
              <div class="flex-1">
                <h1 class="text-2xl font-display font-semibold mb-4">
                  <%= @project.title %>
                </h1>
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
                <div class="text-indigo-400 font-medium text-xl">
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

          <div class="grid grid-cols-3 gap-8">
            <%!-- Main Content --%>
            <div class="col-span-2 space-y-8">
              <%!-- Project Details --%>
              <div class="bg-white/[7.5%] rounded-lg p-6">
                <h2 class="text-lg font-semibold mb-4">Project Details</h2>
                <div class="prose prose-invert max-w-none">
                  <div class="whitespace-pre-line text-gray-300">
                    <%= @project.description %>
                  </div>
                </div>
              </div>

              <%!-- Skills Required --%>
              <div class="bg-white/[7.5%] rounded-lg p-6">
                <h2 class="text-lg font-semibold mb-4">Skills Required</h2>
                <div class="flex flex-wrap gap-2">
                  <%= for skill <- @project.skills do %>
                    <span class="text-white rounded-xl px-3 py-1 text-sm ring-1 ring-white/20">
                      <%= skill %>
                    </span>
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- Sidebar --%>
            <div class="space-y-8">
              <%!-- Apply Button --%>
              <button class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-4 rounded-lg transition">
                Apply Now
              </button>

              <%!-- Project Scope --%>
              <div class="bg-white/[7.5%] rounded-lg p-6">
                <h2 class="text-lg font-semibold mb-4">Project Scope</h2>
                <div class="space-y-4">
                  <div class="flex items-center justify-between text-sm">
                    <div class="text-gray-400">Experience Level</div>
                    <div class="flex items-center gap-2">
                      <.icon name="tabler-chart-bar" class="w-4 h-4" />
                      <%= String.capitalize(@project.scope.experience) %>
                    </div>
                  </div>
                  <div class="flex items-center justify-between text-sm">
                    <div class="text-gray-400">Project Length</div>
                    <div class="flex items-center gap-2">
                      <.icon name="tabler-clock" class="w-4 h-4" />
                      <%= String.capitalize(@project.scope.duration) %> term
                    </div>
                  </div>
                  <div class="flex items-center justify-between text-sm">
                    <div class="text-gray-400">Project Size</div>
                    <div class="flex items-center gap-2">
                      <.icon name="tabler-layout-grid" class="w-4 h-4" />
                      <%= String.capitalize(@project.scope.size) %> size
                    </div>
                  </div>
                </div>
              </div>

              <%!-- Client Info --%>
              <div class="bg-white/[7.5%] rounded-lg p-6">
                <h2 class="text-lg font-semibold mb-4">About the Client</h2>
                <div class="flex items-center gap-3 mb-4">
                  <img src={@project.client.avatar_url} class="w-12 h-12 rounded-full" />
                  <div>
                    <div class="font-medium"><%= @project.client.name %></div>
                    <div class="text-sm text-gray-400">
                      <%= @project.client.projects_posted %> projects posted
                    </div>
                  </div>
                </div>
                <div class="space-y-4 text-sm">
                  <div class="flex items-center justify-between">
                    <div class="text-gray-400">Member Since</div>
                    <div><%= Calendar.strftime(@project.client.member_since, "%B %Y") %></div>
                  </div>
                  <div class="flex items-center justify-between">
                    <div class="text-gray-400">Last Active</div>
                    <div>
                      <%= Calendar.strftime(@project.client.last_active, "%B %d, %Y") %>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
