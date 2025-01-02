defmodule AlgoraWeb.Job.ViewLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    # Mock data for a single job (in production, you'd fetch this from your database)
    job = %{
      id: id,
      title: "Senior Elixir Developer",
      country: socket.assigns.current_country,
      tech_stack: ["Elixir", "Phoenix", "Phoenix LiveView", "PostgreSQL"],
      scope: %{size: "medium", duration: "medium", experience: "intermediate"},
      budget: %{type: :hourly, from: 50, to: 75},
      description: """
      Looking for an experienced developer to join our team. The role includes:

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
        jobs_posted: 5,
        member_since: ~D[2023-01-15],
        last_active: ~N[2024-03-20 15:30:00]
      }
    }

    {:ok, assign(socket, job: job)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 p-8 text-white">
      <div class="mx-auto max-w-4xl">
        <div class="mb-6 flex items-center gap-3 text-gray-400">
          <.link navigate={~p"/jobs"} class="transition hover:text-white">
            <.icon name="tabler-arrow-left" class="h-5 w-5" />
          </.link>
          <div class="text-sm">Back to jobs</div>
        </div>

        <div class="space-y-8">
          <%!-- Header Section --%>
          <div class="bg-white/[7.5%] rounded-lg p-6">
            <div class="flex items-start justify-between gap-8">
              <div class="flex-1">
                <h1 class="font-display mb-4 text-2xl font-semibold">
                  {@job.title}
                </h1>
                <div class="flex items-center gap-4 text-sm text-gray-400">
                  <div class="flex items-center gap-1">
                    <.icon name="tabler-clock" class="h-4 w-4" />
                    Posted {Calendar.strftime(@job.posted_at, "%B %d, %Y")}
                  </div>
                  <div class="flex items-center gap-1">
                    <.icon name="tabler-world" class="h-4 w-4" />
                    {@job.country}
                  </div>
                </div>
              </div>
              <div class="text-right">
                <div class="text-xl font-medium text-indigo-400">
                  <%= case @job.budget.type do %>
                    <% :hourly -> %>
                      ${@job.budget.from}-{@job.budget.to}/hour
                    <% :fixed -> %>
                      {Money.to_string!(@job.budget.from)}-{Money.to_string!(@job.budget.to)}
                  <% end %>
                </div>
                <div class="text-sm text-gray-400">
                  {String.capitalize("#{@job.budget.type}")} Rate
                </div>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-3 gap-8">
            <%!-- Main Content --%>
            <div class="col-span-2 space-y-8">
              <%!-- Job Details --%>
              <div class="bg-white/[7.5%] rounded-lg p-6">
                <h2 class="mb-4 text-lg font-semibold">Job Details</h2>
                <div class="max-w-none prose prose-invert">
                  <div class="whitespace-pre-line text-gray-300">
                    {@job.description}
                  </div>
                </div>
              </div>

              <%!-- Tech Stack Required --%>
              <div class="bg-white/[7.5%] rounded-lg p-6">
                <h2 class="mb-4 text-lg font-semibold">Tech Stack Required</h2>
                <div class="flex flex-wrap gap-2">
                  <%= for tech <- @job.tech_stack do %>
                    <span class="rounded-xl px-3 py-1 text-sm text-white ring-1 ring-white/20">
                      {tech}
                    </span>
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- Sidebar --%>
            <div class="space-y-8">
              <%!-- Apply Button --%>
              <button class="w-full rounded-lg bg-indigo-600 px-4 py-3 font-semibold text-white transition hover:bg-indigo-700">
                Apply Now
              </button>

              <%!-- Job Scope --%>
              <div class="bg-white/[7.5%] rounded-lg p-6">
                <h2 class="mb-4 text-lg font-semibold">Job Scope</h2>
                <div class="space-y-4">
                  <div class="flex items-center justify-between text-sm">
                    <div class="text-gray-400">Experience Level</div>
                    <div class="flex items-center gap-2">
                      <.icon name="tabler-chart-bar" class="h-4 w-4" />
                      {String.capitalize(@job.scope.experience)}
                    </div>
                  </div>
                  <div class="flex items-center justify-between text-sm">
                    <div class="text-gray-400">Job Length</div>
                    <div class="flex items-center gap-2">
                      <.icon name="tabler-clock" class="h-4 w-4" />
                      {String.capitalize(@job.scope.duration)} term
                    </div>
                  </div>
                  <div class="flex items-center justify-between text-sm">
                    <div class="text-gray-400">Job Size</div>
                    <div class="flex items-center gap-2">
                      <.icon name="tabler-layout-grid" class="h-4 w-4" />
                      {String.capitalize(@job.scope.size)} size
                    </div>
                  </div>
                </div>
              </div>

              <%!-- Client Info --%>
              <div class="bg-white/[7.5%] rounded-lg p-6">
                <h2 class="mb-4 text-lg font-semibold">About the Client</h2>
                <div class="mb-4 flex items-center gap-3">
                  <img src={@job.client.avatar_url} class="h-12 w-12 rounded-full" />
                  <div>
                    <div class="font-medium">{@job.client.name}</div>
                    <div class="text-sm text-gray-400">
                      {@job.client.jobs_posted} jobs posted
                    </div>
                  </div>
                </div>
                <div class="space-y-4 text-sm">
                  <div class="flex items-center justify-between">
                    <div class="text-gray-400">Member Since</div>
                    <div>{Calendar.strftime(@job.client.member_since, "%B %Y")}</div>
                  </div>
                  <div class="flex items-center justify-between">
                    <div class="text-gray-400">Last Active</div>
                    <div>
                      {Calendar.strftime(@job.client.last_active, "%B %d, %Y")}
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
