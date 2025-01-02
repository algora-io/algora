defmodule AlgoraWeb.Project.IndexLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  def mount(_params, _session, socket) do
    projects = [
      %{
        id: 1,
        title: "Build Real-time Chat Application",
        country: "US",
        tech_stack: ["Elixir", "Phoenix", "Phoenix LiveView", "PostgreSQL"],
        scope: %{size: "medium", duration: "medium", experience: "intermediate"},
        budget: %{type: :hourly, from: Money.new!(50, :USD), to: Money.new!(75, :USD)},
        description: "Looking for an experienced developer to build a real-time chat system...",
        posted_at: ~N[2024-03-15 10:00:00],
        client: %{
          name: "John Doe",
          avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=John",
          projects_posted: 5
        }
      },
      %{
        id: 2,
        title: "E-commerce Platform Development",
        country: "UK",
        tech_stack: ["Elixir", "Phoenix", "PostgreSQL", "JavaScript"],
        scope: %{size: "large", duration: "long", experience: "expert"},
        budget: %{type: :fixed, from: Money.new!(15_000, :USD), to: Money.new!(20_000, :USD)},
        description: "Need to build a scalable e-commerce platform...",
        posted_at: ~N[2024-03-14 15:30:00],
        client: %{
          name: "Sarah Smith",
          avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah",
          projects_posted: 3
        }
      }
    ]

    projects =
      Enum.map(projects, fn project ->
        Map.put(project, :applicants, [
          %{
            name: "Alice Johnson",
            designation: "Senior Developer",
            image: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alice"
          },
          %{
            name: "Bob Smith",
            designation: "Full Stack Engineer",
            image: "https://api.dicebear.com/7.x/avataaars/svg?seed=Bob"
          },
          %{
            name: "Charlie Davis",
            designation: "Senior Developer",
            image: "https://api.dicebear.com/7.x/avataaars/svg?seed=Charlie"
          },
          %{
            name: "Dave Johnson",
            designation: "Full Stack Engineer",
            image: "https://api.dicebear.com/7.x/avataaars/svg?seed=Dave"
          }
        ])
      end)

    {:ok, assign(socket, projects: projects)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen p-8 text-white">
      <div class="mx-auto max-w-6xl">
        <h1 class="font-display mb-8 text-3xl font-semibold">Available Projects</h1>

        <div class="space-y-6">
          <%= for project <- @projects do %>
            <div class="bg-white/[7.5%] rounded-lg p-6 transition hover:bg-white/[10%]">
              <div class="mb-4 flex items-start justify-between">
                <div>
                  <h2 class="mb-2 text-xl font-semibold text-white">
                    <.link
                      navigate={~p"/projects/#{project.id}"}
                      class="transition hover:text-indigo-400"
                    >
                      {project.title}
                    </.link>
                  </h2>
                  <div class="flex items-center gap-4 text-sm text-gray-400">
                    <div class="flex items-center gap-1">
                      <.icon name="tabler-clock" class="h-4 w-4" />
                      {Calendar.strftime(project.posted_at, "%B %d, %Y")}
                    </div>
                    <div class="flex items-center gap-1">
                      <.icon name="tabler-world" class="h-4 w-4" />
                      {project.country}
                    </div>
                  </div>
                </div>
                <div class="text-right">
                  <div class="font-medium text-indigo-400">
                    <%= case project.budget.type do %>
                      <% :hourly -> %>
                        ${project.budget.from}-{project.budget.to}/hour
                      <% :fixed -> %>
                        {Money.to_string!(project.budget.from)}-{Money.to_string!(project.budget.to)}
                    <% end %>
                  </div>
                  <div class="text-sm text-gray-400">
                    {String.capitalize("#{project.budget.type}")} Rate
                  </div>
                </div>
              </div>

              <p class="mb-4 line-clamp-2 text-gray-300">
                {project.description}
              </p>

              <div class="mb-4 flex flex-wrap gap-2">
                <%= for tech <- project.tech_stack do %>
                  <span class="rounded-xl px-3 py-1 text-sm text-white ring-1 ring-white/20">
                    {tech}
                  </span>
                <% end %>
              </div>

              <div class="flex items-center justify-between border-t border-white/10 pt-4">
                <div class="flex items-center gap-3">
                  <img src={project.client.avatar_url} class="h-10 w-10 rounded-full" />
                  <div>
                    <div class="font-medium">{project.client.name}</div>
                    <div class="text-sm text-gray-400">
                      {project.client.projects_posted} projects posted
                    </div>
                  </div>
                </div>

                <div class="flex items-center gap-6">
                  <div id={"applicants-#{project.id}"} phx-hook="AnimatedTooltip" class="flex">
                    <%= for applicant <- project.applicants do %>
                      <div class="group relative -mr-4" data-tooltip-trigger>
                        <div
                          data-tooltip
                          class="absolute -top-16 -left-1/2 z-50 hidden translate-x-1/2 flex-col items-center justify-center whitespace-nowrap rounded-md bg-black px-4 py-2 text-xs shadow-xl"
                        >
                          <div class="w-[20%] absolute inset-x-10 -bottom-px z-30 h-px bg-gradient-to-r from-transparent via-emerald-500 to-transparent">
                          </div>
                          <div class="w-[40%] absolute -bottom-px z-30 h-px bg-gradient-to-r from-transparent via-emerald-500 to-transparent">
                          </div>
                          <div class="relative z-30 text-base font-bold text-white">
                            {applicant.name}
                          </div>
                          <div class="text-xs text-white">{applicant.designation}</div>
                        </div>
                        <img
                          src={applicant.image}
                          alt={applicant.name}
                          class="!m-0 !p-0 relative h-10 w-10 rounded-full border-2 border-white bg-gray-900 object-cover object-top transition duration-500 group-hover:z-30 group-hover:scale-105"
                        />
                      </div>
                    <% end %>
                  </div>

                  <div class="flex items-center gap-3 text-sm">
                    <div class="flex items-center gap-2 text-gray-400">
                      <.icon name="tabler-chart-bar" class="h-4 w-4" />
                      {String.capitalize(project.scope.experience)}
                    </div>
                    <div class="flex items-center gap-2 text-gray-400">
                      <.icon name="tabler-clock" class="h-4 w-4" />
                      {String.capitalize(project.scope.duration)} term
                    </div>
                    <div class="flex items-center gap-2 text-gray-400">
                      <.icon name="tabler-layout-grid" class="h-4 w-4" />
                      {String.capitalize(project.scope.size)} size
                    </div>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
