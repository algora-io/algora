defmodule AlgoraWeb.ProjectWizardLive do
  use AlgoraWeb, :live_view
  alias Algora.Accounts

  def mount(_params, session, socket) do
    project = %{
      country: "US",
      skills: ["Elixir"],
      title: "",
      scope: %{size: nil, duration: nil, experience: nil},
      budget: %{type: :hourly, from: nil, to: nil},
      description: ""
    }

    {:ok,
     socket
     |> assign(step: 1)
     |> assign(total_steps: 5)
     |> assign(project: project)
     |> assign(current_user: %{email: session["user_email"]})
     |> assign(matching_devs: get_matching_devs(project))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white sm:flex">
      <div class="flex-grow p-8 max-w-3xl mx-auto">
        <div class="flex items-center gap-4 text-lg mb-6 font-display">
          <span class="text-gray-300"><%= @step %> / 5</span>
          <h1 class="text-lg text-gray-200 font-semibold uppercase">Create Your Project</h1>
        </div>
        <div class="mb-8">
          <%= render_step(assigns) %>
        </div>
        <div class="flex justify-between">
          <%= if @step > 1 do %>
            <button
              phx-click="prev_step"
              class="bg-gray-600 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded"
            >
              Previous
            </button>
          <% else %>
            <div></div>
          <% end %>
          <%= if @step < @total_steps do %>
            <button
              phx-click="next_step"
              class="bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-4 rounded"
            >
              Next: <%= next_step_label(@step) %>
            </button>
          <% else %>
            <button
              phx-click="submit"
              class="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded"
            >
              Submit Project
            </button>
          <% end %>
        </div>
      </div>
      <div class="sm:w-1/3 border-l-2 border-gray-800 bg-gradient-to-b from-gray-950 to-gray-900 px-8 py-4 overflow-y-auto">
        <h2 class="text-lg text-gray-200 font-semibold uppercase mb-4">Matching Developers</h2>
        <%= if @matching_devs == [] do %>
          <p class="text-gray-400">Add skills to see matching developers</p>
        <% else %>
          <%= for dev <- @matching_devs do %>
            <div class="mb-4 bg-gray-800 p-3 rounded">
              <div class="flex items-center mb-2">
                <img src={dev.avatar_url} alt={dev.name} class="w-10 h-10 rounded-full mr-3" />
                <div>
                  <div class="font-semibold"><%= dev.name %></div>
                  <div class="text-sm text-gray-400">@<%= dev.handle %> <%= dev.flag %></div>
                </div>
              </div>
              <div class="text-sm">
                <div class="mb-1">Skills: <%= Enum.join(dev.skills, ", ") %></div>
                <div>
                  Earned: $<%= dev.amount %> | Bounties: <%= dev.bounties %> | Projects: <%= dev.projects %>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  def render_step(%{step: 1} = assigns) do
    ~H"""
    <div class="space-y-8">
      <h2 class="text-4xl font-semibold text-white">
        Which specific skills do you need your Elixir developer to have?
      </h2>

      <div>
        <input
          type="text"
          placeholder="Desired areas of expertise"
          class="w-full p-4 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      <div class="flex flex-wrap gap-3">
        <%= for skill <- ["Elixir", "Phoenix", "Phoenix LiveView", "PostgreSQL"] do %>
          <div class="bg-blue-900 text-blue-200 rounded-full px-4 py-2 text-sm font-semibold flex items-center">
            <%= skill %>
            <button
              phx-click="remove_skill"
              phx-value-skill={skill}
              class="ml-2 text-blue-300 hover:text-blue-100"
            >
              ×
            </button>
          </div>
        <% end %>
      </div>

      <div>
        <h3 class="text-lg font-medium text-gray-400 mb-3">Popular skills for Software Developers</h3>
        <div class="flex flex-wrap gap-3">
          <%= for skill <- ["JavaScript", "CSS", "PHP", "React", "HTML", "Node.js", "iOS", "MySQL", "Python", "HTML5"] do %>
            <button
              phx-click="add_skill"
              phx-value-skill={skill}
              class="bg-gray-800 hover:bg-gray-700 text-white rounded-full px-4 py-2 text-sm font-semibold flex items-center"
            >
              + <%= skill %>
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def render_step(%{step: 2} = assigns) do
    ~H"""
    <div>
      <div class="mb-4">
        <label class="block text-sm font-medium text-gray-300 mb-1">Project Name</label>
        <input
          type="text"
          phx-value-field="title"
          phx-blur="update_project"
          value={@project.title}
          placeholder="Enter project name"
          class="w-full p-2 bg-gray-800 border border-gray-700 rounded text-white"
        />
      </div>
    </div>
    """
  end

  def render_step(%{step: 3} = assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl font-semibold mb-4">Define the project scope</h2>
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-300">Project size</label>
          <select
            name="scope[size]"
            phx-change="update_project"
            phx-value-field="scope.size"
            class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
          >
            <option value="">Select size</option>
            <option value="small" selected={@project.scope.size == "small"}>Small</option>
            <option value="medium" selected={@project.scope.size == "medium"}>Medium</option>
            <option value="large" selected={@project.scope.size == "large"}>Large</option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-300">Project duration</label>
          <select
            name="scope[duration]"
            phx-change="update_project"
            phx-value-field="scope.duration"
            class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
          >
            <option value="">Select duration</option>
            <option value="short" selected={@project.scope.duration == "short"}>Short term</option>
            <option value="medium" selected={@project.scope.duration == "medium"}>Medium term</option>
            <option value="long" selected={@project.scope.duration == "long"}>Long term</option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-300">Experience level</label>
          <select
            name="scope[experience]"
            phx-change="update_project"
            phx-value-field="scope.experience"
            class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
          >
            <option value="">Select experience level</option>
            <option value="entry" selected={@project.scope.experience == "entry"}>Entry</option>
            <option value="intermediate" selected={@project.scope.experience == "intermediate"}>
              Intermediate
            </option>
            <option value="expert" selected={@project.scope.experience == "expert"}>Expert</option>
          </select>
        </div>
      </div>
    </div>
    """
  end

  def render_step(%{step: 4} = assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl font-semibold mb-4">Set your budget</h2>
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-300">Budget type</label>
          <select
            name="budget[type]"
            phx-change="update_project"
            phx-value-field="budget.type"
            class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
          >
            <option value="hourly" selected={@project.budget.type == :hourly}>Hourly rate</option>
            <option value="fixed" selected={@project.budget.type == :fixed}>Fixed price</option>
          </select>
        </div>
        <div class="flex space-x-4">
          <div class="flex-1">
            <label class="block text-sm font-medium text-gray-300">From</label>
            <input
              type="number"
              name="budget[from]"
              value={@project.budget.from}
              phx-blur="update_project"
              phx-value-field="budget.from"
              class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
            />
          </div>
          <div class="flex-1">
            <label class="block text-sm font-medium text-gray-300">To</label>
            <input
              type="number"
              name="budget[to]"
              value={@project.budget.to}
              phx-blur="update_project"
              phx-value-field="budget.to"
              class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render_step(%{step: 5} = assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl font-semibold mb-4">Describe your project</h2>
      <div>
        <textarea
          name="description"
          rows="6"
          phx-blur="update_project"
          phx-value-field="description"
          class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
          placeholder="Provide a detailed description of your project..."
        ><%= @project.description %></textarea>
      </div>
    </div>
    """
  end

  def handle_event("update_project", %{"field" => field, "value" => value} = params, socket) do
    updated_project = update_project_field(socket.assigns.project, field, value, params)
    matching_devs = get_matching_devs(updated_project)
    {:noreply, assign(socket, project: updated_project, matching_devs: matching_devs)}
  end

  defp update_project_field(project, "skills", _value, %{"skill" => skill}) do
    skills =
      if skill in project.skills,
        do: List.delete(project.skills, skill),
        else: [skill | project.skills]

    %{project | skills: skills}
  end

  defp update_project_field(project, "scope." <> scope_field, value, _params) do
    scope = Map.put(project.scope, String.to_atom(scope_field), value)
    %{project | scope: scope}
  end

  defp update_project_field(project, "budget." <> budget_field, value, _params) do
    budget = Map.put(project.budget, String.to_atom(budget_field), value)
    %{project | budget: budget}
  end

  defp update_project_field(project, field, value, _params) do
    Map.put(project, String.to_atom(field), value)
  end

  def handle_event("next_step", _, socket) do
    {:noreply, assign(socket, step: socket.assigns.step + 1)}
  end

  def handle_event("prev_step", _, socket) do
    {:noreply, assign(socket, step: socket.assigns.step - 1)}
  end

  def handle_event("submit", _, socket) do
    # Handle project submission
    {:noreply, socket}
  end

  def handle_event("add_skill", %{"skill" => skill}, socket) do
    updated_skills = [skill | socket.assigns.project.skills] |> Enum.uniq()
    updated_project = Map.put(socket.assigns.project, :skills, updated_skills)
    {:noreply, assign(socket, project: updated_project)}
  end

  def handle_event("remove_skill", %{"skill" => skill}, socket) do
    updated_skills = List.delete(socket.assigns.project.skills, skill)
    updated_project = Map.put(socket.assigns.project, :skills, updated_skills)
    {:noreply, assign(socket, project: updated_project)}
  end

  defp next_step_label(1), do: "Project Name"
  defp next_step_label(2), do: "Scope"
  defp next_step_label(3), do: "Budget"
  defp next_step_label(4), do: "Description"

  defp get_matching_devs(project) do
    Accounts.list_matching_devs(limit: 5, country: project.country, skills: project.skills)
  end
end
