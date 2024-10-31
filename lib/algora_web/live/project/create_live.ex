defmodule AlgoraWeb.Project.CreateLive do
  use AlgoraWeb, :live_view
  alias Algora.Accounts
  alias Algora.Money

  def mount(_params, session, socket) do
    project = %{
      country: "US",
      skills: ["Elixir"],
      title: "",
      budget: %{type: :fixed, fixed_price: nil},
      description: "",
      visibility: :public
    }

    {:ok,
     socket
     |> assign(step: 1)
     |> assign(total_steps: 4)
     |> assign(project: project)
     |> assign(current_user: %{email: session["user_email"]})
     |> assign(matching_devs: get_matching_devs(project))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-tl from-indigo-950 to-black text-white flex flex-col sm:flex-row">
      <div class="flex-grow px-4 sm:px-8 py-8 sm:py-16 bg-gray-950/25">
        <div class="max-w-3xl mx-auto">
          <div class="flex items-center gap-4 text-lg mb-6 font-display">
            <span class="text-gray-300"><%= @step %> / <%= @total_steps %></span>
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
                class="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded"
              >
                Next: <%= next_step_label(@step) %>
              </button>
            <% else %>
              <button
                phx-click="submit"
                class="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded"
              >
                Submit Project
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <div class="font-display w-full sm:w-1/3 border-t-2 sm:border-t-0 sm:border-l-2 border-gray-800 bg-gradient-to-b from-white/[5%] to-white/[2.5%] px-4 sm:px-8 py-4 overflow-y-auto sm:max-h-screen">
        <h2 class="text-lg text-gray-200 font-display font-semibold uppercase mb-4">
          Matching Developers
        </h2>
        <%= if @matching_devs == [] do %>
          <p class="text-gray-400">Add skills to see matching developers</p>
        <% else %>
          <%= for dev <- @matching_devs do %>
            <div class="mb-4 bg-white/[7.5%] p-4 rounded-lg">
              <div class="flex mb-2 gap-3">
                <img
                  src={dev.avatar_url}
                  alt={dev.name}
                  class="w-16 h-16 sm:w-24 sm:h-24 rounded-full mr-3"
                />
                <div class="flex-grow min-w-0">
                  <div class="flex justify-between">
                    <div class="min-w-0">
                      <div class="font-semibold text-base sm:text-lg font-display truncate">
                        <%= dev.name %> <%= dev.flag %>
                      </div>
                      <div class="text-sm text-gray-400 truncate">@<%= dev.handle %></div>
                    </div>
                    <div class="flex flex-col items-end ml-2">
                      <div class="text-gray-300 text-sm">Earned</div>
                      <div class="text-white font-semibold text-base sm:text-lg font-display">
                        <%= Money.format!(dev.amount, "USD") %>
                      </div>
                    </div>
                  </div>

                  <div class="-m-1 pt-2 sm:pt-3 text-sm">
                    <div class="p-1 overflow-x-auto flex gap-2 scrollbar-thin pb-4">
                      <%= for skill <- dev.skills do %>
                        <span class="text-white rounded-xl px-2 py-0.5 text-xs sm:text-sm ring-1 ring-white/40 whitespace-nowrap">
                          <%= skill %>
                        </span>
                      <% end %>
                    </div>
                  </div>
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
        What is your tech stack?
      </h2>

      <div>
        <input
          type="text"
          placeholder="Desired areas of expertise"
          class="w-full px-3 py-2 bg-indigo-200/5 border border-gray-700 rounded-sm text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
        />
      </div>

      <div class="flex flex-wrap gap-3">
        <%= for skill <- ["Elixir", "Phoenix", "Phoenix LiveView", "PostgreSQL"] do %>
          <div class="bg-indigo-900 text-indigo-200 rounded-full px-4 py-2 text-sm font-semibold flex items-center">
            <%= skill %>
            <button
              phx-click="remove_skill"
              phx-value-skill={skill}
              class="ml-2 text-indigo-300 hover:text-indigo-100"
            >
              ×
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def render_step(%{step: 2} = assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl font-semibold mb-4">Project Details</h2>
      <div class="space-y-8">
        <div>
          <label class="block text-sm font-medium text-gray-300 mb-2">Title</label>
          <input
            type="text"
            phx-value-field="title"
            phx-blur="update_project"
            value={@project.title}
            placeholder="Looking for an Elixir developer to build and maintain a livestreaming app"
            class="w-full px-3 py-2 bg-indigo-200/5 border border-gray-700 rounded-sm text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>

        <fieldset class="mb-8">
          <legend class="text-sm font-medium text-gray-300 mb-2">Discovery</legend>
          <div class="mt-1 grid grid-cols-1 gap-y-6 sm:grid-cols-2 sm:gap-x-4">
            <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @project.visibility == :public, do: 'border-indigo-600 ring-2 ring-indigo-600 bg-gray-800', else: 'border-gray-700 bg-gray-900'}"}>
              <input
                type="radio"
                name="visibility"
                value="public"
                checked={@project.visibility == :public}
                class="sr-only"
                phx-click="update_project"
                phx-value-field="visibility"
              />
              <span class="flex flex-1">
                <span class="flex flex-col">
                  <span class="block text-sm font-medium text-gray-200">Algora Network</span>
                  <span class="mt-1 flex items-center text-sm text-gray-400">
                    Open to our vetted developer network
                  </span>
                  <span class="mt-6 text-sm font-medium text-gray-300">
                    Best for finding new talent quickly
                  </span>
                </span>
              </span>
              <svg
                class={"h-5 w-5 text-indigo-600 #{if @project.visibility != :public, do: 'invisible'}"}
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                  clip-rule="evenodd"
                />
              </svg>
              <span
                class={"pointer-events-none absolute -inset-px rounded-lg #{if @project.visibility == :public, do: 'border border-indigo-600', else: 'border-2 border-transparent'}"}
                aria-hidden="true"
              >
              </span>
            </label>

            <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @project.visibility == :private, do: 'border-indigo-600 ring-2 ring-indigo-600 bg-gray-800', else: 'border-gray-700 bg-gray-900'}"}>
              <input
                type="radio"
                name="visibility"
                value="private"
                checked={@project.visibility == :private}
                class="sr-only"
                phx-click="update_project"
                phx-value-field="visibility"
              />
              <span class="flex flex-1">
                <span class="flex flex-col">
                  <span class="block text-sm font-medium text-gray-200">Bring Your Own</span>
                  <span class="mt-1 flex items-center text-sm text-gray-400">
                    Invite specific developers
                  </span>
                  <span class="mt-6 text-sm font-medium text-gray-300">
                    Best for working with known teams
                  </span>
                </span>
              </span>
              <svg
                class={"h-5 w-5 text-indigo-600 #{if @project.visibility != :private, do: 'invisible'}"}
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                  clip-rule="evenodd"
                />
              </svg>
              <span
                class={"pointer-events-none absolute -inset-px rounded-lg #{if @project.visibility == :private, do: 'border border-indigo-600', else: 'border-2 border-transparent'}"}
                aria-hidden="true"
              >
              </span>
            </label>
          </div>
        </fieldset>
      </div>
    </div>
    """
  end

  def render_step(%{step: 3} = assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl font-semibold mb-4">Collaboration Details</h2>
      <div class="space-y-8">
        <fieldset>
          <legend class="text-sm font-medium text-gray-300 mb-2">Collaboration Type</legend>
          <div class="mt-1 grid grid-cols-1 gap-y-6 sm:grid-cols-2 sm:gap-x-4">
            <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @project.budget.type == :fixed, do: 'border-indigo-600 ring-2 ring-indigo-600 bg-gray-800', else: 'border-gray-700 bg-gray-900'}"}>
              <input
                type="radio"
                name="budget[type]"
                value="fixed"
                checked={@project.budget.type == :fixed}
                class="sr-only"
                phx-click="update_project"
                phx-value-field="budget.type"
              />
              <span class="flex flex-1">
                <span class="flex flex-col">
                  <span class="flex items-center gap-2">
                    <span class="block text-sm font-medium text-gray-200">Outcome-Based</span>
                    <%= if @project.visibility == :public do %>
                      <span class="text-xs font-display font-medium text-indigo-400">
                        15% platform fee
                      </span>
                    <% else %>
                      <span class="text-xs font-display font-medium text-indigo-400">
                        5% platform fee
                      </span>
                      <span class="text-xs font-display font-medium text-emerald-400">
                        First $5k free
                      </span>
                    <% end %>
                  </span>
                  <span class="mt-1 flex items-center text-sm text-gray-400">
                    Pay for milestones & bounties
                  </span>
                  <span class="mt-6 text-sm font-medium text-gray-300">
                    Best for specific deliverables and features
                  </span>
                </span>
              </span>
              <svg
                class={"h-5 w-5 text-indigo-600 #{if @project.budget.type != :fixed, do: 'invisible'}"}
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                  clip-rule="evenodd"
                />
              </svg>
            </label>

            <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @project.budget.type == :hourly, do: 'border-indigo-600 ring-2 ring-indigo-600 bg-gray-800', else: 'border-gray-700 bg-gray-900'}"}>
              <input
                type="radio"
                name="budget[type]"
                value="hourly"
                checked={@project.budget.type == :hourly}
                class="sr-only"
                phx-click="update_project"
                phx-value-field="budget.type"
              />
              <span class="flex flex-1">
                <span class="flex flex-col">
                  <span class="flex items-center gap-2">
                    <span class="block text-sm font-medium text-gray-200">Time-Based</span>
                    <%= if @project.visibility == :public do %>
                      <span class="text-xs font-display font-medium text-indigo-400">
                        5% platform fee
                      </span>
                    <% else %>
                      <span class="text-xs font-display font-medium text-indigo-400">
                        5% platform fee
                      </span>
                      <span class="text-xs font-display font-medium text-emerald-400">
                        First $5k free
                      </span>
                    <% end %>
                  </span>
                  <span class="mt-1 flex items-center text-sm text-gray-400">Pay an hourly rate</span>
                  <span class="mt-6 text-sm font-medium text-gray-300">
                    Best for ongoing collab and complex projects
                  </span>
                </span>
              </span>
              <svg
                class={"h-5 w-5 text-indigo-600 #{if @project.budget.type != :hourly, do: 'invisible'}"}
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                  clip-rule="evenodd"
                />
              </svg>
            </label>
          </div>
        </fieldset>

        <%= if @project.budget.type == :hourly do %>
          <div class="grid sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-300 mb-2">
                Expected Hours per Week
              </label>
              <input
                name="budget[hours_per_week]"
                value={@project.budget.hours_per_week}
                phx-blur="update_project"
                phx-value-field="budget.hours_per_week"
                class="w-full px-3 py-2 bg-indigo-200/5 border border-gray-700 rounded-sm text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-300 mb-2">Hourly Rate</label>
              <input
                name="budget[hourly_rate]"
                value={@project.budget.hourly_rate}
                phx-blur="update_project"
                phx-value-field="budget.hourly_rate"
                class="w-full px-3 py-2 bg-indigo-200/5 border border-gray-700 rounded-sm text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>
        <% else %>
          <div>
            <label class="block text-sm font-medium text-gray-300 mb-2">Project Budget</label>
            <input
              name="budget[fixed_price]"
              value={@project.budget.fixed_price}
              placeholder="$5,000"
              phx-blur="update_project"
              phx-value-field="budget.fixed_price"
              class="text-base font-semibold font-display w-full px-3 py-2 bg-indigo-200/5 border border-gray-700 rounded-sm text-emerald-300 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def render_step(%{step: 4} = assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl font-semibold mb-4">Describe your project</h2>
      <div>
        <textarea
          name="description"
          rows="6"
          phx-blur="update_project"
          phx-value-field="description"
          class="w-full px-3 py-2 bg-indigo-200/5 border border-gray-700 rounded-sm text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          placeholder="Provide a detailed description of your project..."
        ><%= @project.description %></textarea>
      </div>
    </div>
    """
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

  defp update_project_field(project, "budget.type", value, _params) do
    new_budget =
      case value do
        "fixed" -> %{type: :fixed, fixed_price: nil}
        "hourly" -> %{type: :hourly, hourly_rate: nil, hours_per_week: nil}
      end

    %{project | budget: new_budget}
  end

  defp update_project_field(project, "budget." <> budget_field, value, _params) do
    budget = Map.put(project.budget, String.to_atom(budget_field), value)
    %{project | budget: budget}
  end

  defp update_project_field(project, "visibility", value, _params) do
    %{project | visibility: String.to_atom(value)}
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

  def handle_event("update_project", %{"field" => field, "value" => value} = params, socket) do
    updated_project = update_project_field(socket.assigns.project, field, value, params)
    matching_devs = get_matching_devs(updated_project)
    {:noreply, assign(socket, project: updated_project, matching_devs: matching_devs)}
  end

  defp next_step_label(1), do: "Project Details"
  defp next_step_label(2), do: "Collaboration"
  defp next_step_label(3), do: "Description"
  defp next_step_label(4), do: "Review"

  defp get_matching_devs(project) do
    Accounts.list_matching_devs(limit: 5, country: project.country, skills: project.skills)
  end
end
