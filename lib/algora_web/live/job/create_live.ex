defmodule AlgoraWeb.Job.CreateLive do
  use AlgoraWeb, :live_view
  alias Algora.Accounts
  alias Algora.Money

  def mount(_params, session, socket) do
    job = %{
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
     |> assign(job: job)
     |> assign(current_user: %{email: session["user_email"]})
     |> assign(matching_devs: get_matching_devs(job))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white sm:flex">
      <div class="flex-grow p-8 max-w-3xl mx-auto">
        <div class="flex items-center gap-4 text-lg mb-6 font-display">
          <span class="text-gray-300"><%= @step %> / 5</span>
          <h1 class="text-lg text-gray-200 font-semibold uppercase">Create Your Job</h1>
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
              Submit Job
            </button>
          <% end %>
        </div>
      </div>
      <div class="sm:w-1/3 border-l-2 border-gray-800 bg-gradient-to-b from-white/[5%] to-white/[2.5%] px-8 py-4 overflow-y-auto">
        <h2 class="text-lg text-gray-200 font-display font-semibold uppercase mb-4">
          Matching Developers
        </h2>
        <%= if @matching_devs == [] do %>
          <p class="text-gray-400">Add skills to see matching developers</p>
        <% else %>
          <%= for dev <- @matching_devs do %>
            <div class="mb-4 bg-white/[7.5%] p-4 rounded-lg">
              <div class="flex mb-2 gap-3">
                <img src={dev.avatar_url} alt={dev.name} class="w-24 h-24 rounded-full mr-3" />
                <div>
                  <div class="flex justify-between">
                    <div>
                      <div class="font-semibold"><%= dev.name %> <%= dev.flag %></div>
                      <div class="text-sm text-gray-400">@<%= dev.handle %></div>
                    </div>
                    <div class="flex flex-col items-end">
                      <div class="text-gray-300">Earned</div>
                      <div class="text-white font-semibold">
                        <%= Money.format!(dev.amount, "USD") %>
                      </div>
                    </div>
                  </div>

                  <div class="pt-3 text-sm">
                    <div class="-ml-1 text-sm flex flex-wrap gap-1">
                      <%= for skill <- dev.skills do %>
                        <span class="text-white rounded-xl px-2 py-0.5 text-sm ring-1 ring-white/20">
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
        Which specific skills do you need your Elixir developer to have?
      </h2>

      <div>
        <input
          type="text"
          placeholder="Desired areas of expertise"
          class="w-full p-4 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-purple-500"
        />
      </div>

      <div class="flex flex-wrap gap-3">
        <%= for skill <- ["Elixir", "Phoenix", "Phoenix LiveView", "PostgreSQL"] do %>
          <div class="bg-purple-900 text-purple-200 rounded-full px-4 py-2 text-sm font-semibold flex items-center">
            <%= skill %>
            <button
              phx-click="remove_skill"
              phx-value-skill={skill}
              class="ml-2 text-purple-300 hover:text-purple-100"
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
        <label class="block text-sm font-medium text-gray-300 mb-1">Job Name</label>
        <input
          type="text"
          phx-value-field="title"
          phx-blur="update_job"
          value={@job.title}
          placeholder="Enter job name"
          class="w-full p-2 bg-gray-800 border border-gray-700 rounded text-white"
        />
      </div>
    </div>
    """
  end

  def render_step(%{step: 3} = assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl font-semibold mb-4">Define the job scope</h2>
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-300">Job size</label>
          <select
            name="scope[size]"
            phx-change="update_job"
            phx-value-field="scope.size"
            class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
          >
            <option value="">Select size</option>
            <option value="small" selected={@job.scope.size == "small"}>Small</option>
            <option value="medium" selected={@job.scope.size == "medium"}>Medium</option>
            <option value="large" selected={@job.scope.size == "large"}>Large</option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-300">Job duration</label>
          <select
            name="scope[duration]"
            phx-change="update_job"
            phx-value-field="scope.duration"
            class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
          >
            <option value="">Select duration</option>
            <option value="short" selected={@job.scope.duration == "short"}>Short term</option>
            <option value="medium" selected={@job.scope.duration == "medium"}>Medium term</option>
            <option value="long" selected={@job.scope.duration == "long"}>Long term</option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-300">Experience level</label>
          <select
            name="scope[experience]"
            phx-change="update_job"
            phx-value-field="scope.experience"
            class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
          >
            <option value="">Select experience level</option>
            <option value="entry" selected={@job.scope.experience == "entry"}>Entry</option>
            <option value="intermediate" selected={@job.scope.experience == "intermediate"}>
              Intermediate
            </option>
            <option value="expert" selected={@job.scope.experience == "expert"}>Expert</option>
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
            phx-change="update_job"
            phx-value-field="budget.type"
            class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
          >
            <option value="hourly" selected={@job.budget.type == :hourly}>Hourly rate</option>
            <option value="fixed" selected={@job.budget.type == :fixed}>Fixed price</option>
          </select>
        </div>
        <div class="flex space-x-4">
          <div class="flex-1">
            <label class="block text-sm font-medium text-gray-300">From</label>
            <input
              type="number"
              name="budget[from]"
              value={@job.budget.from}
              phx-blur="update_job"
              phx-value-field="budget.from"
              class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
            />
          </div>
          <div class="flex-1">
            <label class="block text-sm font-medium text-gray-300">To</label>
            <input
              type="number"
              name="budget[to]"
              value={@job.budget.to}
              phx-blur="update_job"
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
      <h2 class="text-2xl font-semibold mb-4">Describe your job</h2>
      <div>
        <textarea
          name="description"
          rows="6"
          phx-blur="update_job"
          phx-value-field="description"
          class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-purple-500 focus:border-purple-500 sm:text-sm rounded-md bg-gray-700 text-white"
          placeholder="Provide a detailed description of your job..."
        ><%= @job.description %></textarea>
      </div>
    </div>
    """
  end

  defp update_job_field(job, "skills", _value, %{"skill" => skill}) do
    skills =
      if skill in job.skills,
        do: List.delete(job.skills, skill),
        else: [skill | job.skills]

    %{job | skills: skills}
  end

  defp update_job_field(job, "scope." <> scope_field, value, _params) do
    scope = Map.put(job.scope, String.to_atom(scope_field), value)
    %{job | scope: scope}
  end

  defp update_job_field(job, "budget." <> budget_field, value, _params) do
    budget = Map.put(job.budget, String.to_atom(budget_field), value)
    %{job | budget: budget}
  end

  defp update_job_field(job, field, value, _params) do
    Map.put(job, String.to_atom(field), value)
  end

  def handle_event("next_step", _, socket) do
    {:noreply, assign(socket, step: socket.assigns.step + 1)}
  end

  def handle_event("prev_step", _, socket) do
    {:noreply, assign(socket, step: socket.assigns.step - 1)}
  end

  def handle_event("submit", _, socket) do
    # Handle job submission
    {:noreply, socket}
  end

  def handle_event("add_skill", %{"skill" => skill}, socket) do
    updated_skills = [skill | socket.assigns.job.skills] |> Enum.uniq()
    updated_job = Map.put(socket.assigns.job, :skills, updated_skills)
    {:noreply, assign(socket, job: updated_job)}
  end

  def handle_event("remove_skill", %{"skill" => skill}, socket) do
    updated_skills = List.delete(socket.assigns.job.skills, skill)
    updated_job = Map.put(socket.assigns.job, :skills, updated_skills)
    {:noreply, assign(socket, job: updated_job)}
  end

  def handle_event("update_job", %{"field" => field, "value" => value} = params, socket) do
    updated_job = update_job_field(socket.assigns.job, field, value, params)
    matching_devs = get_matching_devs(updated_job)
    {:noreply, assign(socket, job: updated_job, matching_devs: matching_devs)}
  end

  defp next_step_label(1), do: "Job Name"
  defp next_step_label(2), do: "Scope"
  defp next_step_label(3), do: "Budget"
  defp next_step_label(4), do: "Description"

  defp get_matching_devs(job) do
    Accounts.list_matching_devs(limit: 5, country: job.country, skills: job.skills)
  end
end
