defmodule AlgoraWeb.Project.IndexLive do
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
      projects
      |> Enum.map(fn project ->
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
    <div class="min-h-screen text-white p-8">
      <div class="max-w-6xl mx-auto">
        <h1 class="text-3xl font-display font-semibold mb-8">Available Projects</h1>

        <div class="space-y-6">
          <%= for project <- @projects do %>
            <div class="bg-white/[7.5%] rounded-lg p-6 hover:bg-white/[10%] transition">
              <div class="flex justify-between items-start mb-4">
                <div>
                  <h2 class="text-xl font-semibold text-white mb-2">
                    <.link
                      navigate={~p"/projects/#{project.id}"}
                      class="hover:text-indigo-400 transition"
                    >
                      {project.title}
                    </.link>
                  </h2>
                  <div class="flex items-center gap-4 text-gray-400 text-sm">
                    <div class="flex items-center gap-1">
                      <.icon name="tabler-clock" class="w-4 h-4" />
                      {Calendar.strftime(project.posted_at, "%B %d, %Y")}
                    </div>
                    <div class="flex items-center gap-1">
                      <.icon name="tabler-world" class="w-4 h-4" />
                      {project.country}
                    </div>
                  </div>
                </div>
                <div class="text-right">
                  <div class="text-indigo-400 font-medium">
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

              <p class="text-gray-300 mb-4 line-clamp-2">
                {project.description}
              </p>

              <div class="flex flex-wrap gap-2 mb-4">
                <%= for tech <- project.tech_stack do %>
                  <span class="text-white rounded-xl px-3 py-1 text-sm ring-1 ring-white/20">
                    {tech}
                  </span>
                <% end %>
              </div>

              <div class="flex justify-between items-center pt-4 border-t border-white/10">
                <div class="flex items-center gap-3">
                  <img src={project.client.avatar_url} class="w-10 h-10 rounded-full" />
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
                      <div class="-mr-4 relative group" data-tooltip-trigger>
                        <div
                          data-tooltip
                          class="hidden absolute -top-16 -left-1/2 translate-x-1/2 text-xs flex-col items-center justify-center rounded-md bg-black z-50 shadow-xl px-4 py-2 whitespace-nowrap"
                        >
                          <div class="absolute inset-x-10 z-30 w-[20%] -bottom-px bg-gradient-to-r from-transparent via-emerald-500 to-transparent h-px">
                          </div>
                          <div class="absolute w-[40%] z-30 -bottom-px bg-gradient-to-r from-transparent via-emerald-500 to-transparent h-px">
                          </div>
                          <div class="font-bold text-white relative z-30 text-base">
                            {applicant.name}
                          </div>
                          <div class="text-white text-xs">{applicant.designation}</div>
                        </div>
                        <img
                          src={applicant.image}
                          alt={applicant.name}
                          class="object-cover !m-0 !p-0 object-top rounded-full h-10 w-10 border-2 group-hover:scale-105 group-hover:z-30 border-white relative transition duration-500 bg-gray-900"
                        />
                      </div>
                    <% end %>
                  </div>

                  <div class="flex items-center gap-3 text-sm">
                    <div class="flex items-center gap-2 text-gray-400">
                      <.icon name="tabler-chart-bar" class="w-4 h-4" />
                      {String.capitalize(project.scope.experience)}
                    </div>
                    <div class="flex items-center gap-2 text-gray-400">
                      <.icon name="tabler-clock" class="w-4 h-4" />
                      {String.capitalize(project.scope.duration)} term
                    </div>
                    <div class="flex items-center gap-2 text-gray-400">
                      <.icon name="tabler-layout-grid" class="w-4 h-4" />
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
