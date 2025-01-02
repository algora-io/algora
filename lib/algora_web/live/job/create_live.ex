defmodule AlgoraWeb.Job.CreateLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Users

  def mount(_params, session, socket) do
    job = %{
      country: socket.assigns.current_country,
      tech_stack: ["Elixir"],
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
      <div class="mx-auto max-w-3xl flex-grow p-8">
        <div class="font-display mb-6 flex items-center gap-4 text-lg">
          <span class="text-gray-300">{@step} / 5</span>
          <h1 class="text-lg font-semibold uppercase text-gray-200">Create Your Job</h1>
        </div>
        <div class="mb-8">
          {render_step(assigns)}
        </div>
        <div class="flex justify-between">
          <%= if @step > 1 do %>
            <button
              phx-click="prev_step"
              class="rounded bg-gray-600 px-4 py-2 font-bold text-white hover:bg-gray-700"
            >
              Previous
            </button>
          <% else %>
            <div></div>
          <% end %>
          <%= if @step < @total_steps do %>
            <button
              phx-click="next_step"
              class="rounded bg-indigo-600 px-4 py-2 font-bold text-white hover:bg-indigo-700"
            >
              Next: {next_step_label(@step)}
            </button>
          <% else %>
            <button
              phx-click="submit"
              class="rounded bg-emerald-600 px-4 py-2 font-bold text-white hover:bg-emerald-700"
            >
              Submit Job
            </button>
          <% end %>
        </div>
      </div>
      <div class="font-display from-white/[5%] to-white/[2.5%] overflow-y-auto border-l-2 border-gray-800 bg-gradient-to-b px-8 py-4 sm:max-h-screen sm:w-1/3">
        <h2 class="font-display mb-4 text-lg font-semibold uppercase text-gray-200">
          Matching Developers
        </h2>
        <%= if @matching_devs == [] do %>
          <p class="text-gray-400">Add tech_stack to see matching developers</p>
        <% else %>
          <%= for dev <- @matching_devs do %>
            <div class="bg-white/[7.5%] mb-4 rounded-lg p-4">
              <div class="mb-2 flex gap-3">
                <img src={dev.avatar_url} alt={dev.name} class="mr-3 h-24 w-24 rounded-full" />
                <div class="flex-grow">
                  <div class="flex justify-between">
                    <div>
                      <div class="font-semibold">{dev.name} {dev.flag}</div>
                      <div class="text-sm text-gray-400">@{dev.handle}</div>
                    </div>
                    <div class="flex flex-col items-end">
                      <div class="text-gray-300">Earned</div>
                      <div class="font-semibold text-white">
                        {Money.to_string!(dev.total_earned)}
                      </div>
                    </div>
                  </div>

                  <div class="pt-3 text-sm">
                    <div class="-ml-1 flex flex-wrap gap-1 text-sm">
                      <%= for tech <- dev.tech_stack do %>
                        <span class="rounded-xl px-2 py-0.5 text-sm text-white ring-1 ring-white/20">
                          {tech}
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
        Which specific tech stack do you need your Elixir developer to have?
      </h2>

      <div>
        <input
          type="text"
          placeholder="Desired areas of expertise"
          class="w-full rounded-lg border border-gray-700 bg-gray-800 p-4 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
        />
      </div>

      <div class="flex flex-wrap gap-3">
        <%= for tech <- ["Elixir", "Phoenix", "Phoenix LiveView", "PostgreSQL"] do %>
          <div class="flex items-center rounded-full bg-indigo-900 px-4 py-2 text-sm font-semibold text-indigo-200">
            {tech}
            <button
              phx-click="remove_tech"
              phx-value-tech={tech}
              class="ml-2 text-indigo-300 hover:text-indigo-100"
            >
              ×
            </button>
          </div>
        <% end %>
      </div>

      <div>
        <h3 class="mb-3 text-lg font-medium text-gray-400">
          Popular tech stacks for Software Developers
        </h3>
        <div class="flex flex-wrap gap-3">
          <%= for tech <- ["JavaScript", "CSS", "PHP", "React", "HTML", "Node.js", "iOS", "MySQL", "Python", "HTML5"] do %>
            <button
              phx-click="add_tech"
              phx-value-tech={tech}
              class="flex items-center rounded-full bg-gray-800 px-4 py-2 text-sm font-semibold text-white hover:bg-gray-700"
            >
              + {tech}
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
        <label class="mb-1 block text-sm font-medium text-gray-300">Job Name</label>
        <input
          type="text"
          phx-value-field="title"
          phx-blur="update_job"
          value={@job.title}
          placeholder="Enter job name"
          class="w-full rounded border border-gray-700 bg-gray-800 p-2 text-white"
        />
      </div>
    </div>
    """
  end

  def render_step(%{step: 3} = assigns) do
    ~H"""
    <div>
      <h2 class="mb-4 text-2xl font-semibold">Define the job scope</h2>
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-300">Job size</label>
          <select
            name="scope[size]"
            phx-change="update_job"
            phx-value-field="scope.size"
            class="mt-1 block w-full rounded-md border-gray-300 bg-gray-700 py-2 pr-10 pl-3 text-base text-white focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
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
            class="mt-1 block w-full rounded-md border-gray-300 bg-gray-700 py-2 pr-10 pl-3 text-base text-white focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
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
            class="mt-1 block w-full rounded-md border-gray-300 bg-gray-700 py-2 pr-10 pl-3 text-base text-white focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
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
      <h2 class="mb-4 text-2xl font-semibold">Set your budget</h2>
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-300">Budget type</label>
          <select
            name="budget[type]"
            phx-change="update_job"
            phx-value-field="budget.type"
            class="mt-1 block w-full rounded-md border-gray-300 bg-gray-700 py-2 pr-10 pl-3 text-base text-white focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
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
              class="mt-1 block w-full rounded-md border-gray-300 bg-gray-700 py-2 pr-10 pl-3 text-base text-white focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
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
              class="mt-1 block w-full rounded-md border-gray-300 bg-gray-700 py-2 pr-10 pl-3 text-base text-white focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
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
      <h2 class="mb-4 text-2xl font-semibold">Describe your job</h2>
      <div>
        <textarea
          name="description"
          rows="6"
          phx-blur="update_job"
          phx-value-field="description"
          class="mt-1 block w-full rounded-md border-gray-300 bg-gray-700 py-2 pr-10 pl-3 text-base text-white focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
          placeholder="Provide a detailed description of your job..."
        ><%= @job.description %></textarea>
      </div>
    </div>
    """
  end

  defp update_job_field(job, "tech_stack", _value, %{"tech" => tech}) do
    tech_stack =
      if tech in job.tech_stack,
        do: List.delete(job.tech_stack, tech),
        else: [tech | job.tech_stack]

    %{job | tech_stack: tech_stack}
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

  def handle_event("add_tech", %{"tech" => tech}, socket) do
    updated_tech_stack = Enum.uniq([tech | socket.assigns.job.tech_stack])
    updated_job = Map.put(socket.assigns.job, :tech_stack, updated_tech_stack)
    {:noreply, assign(socket, job: updated_job)}
  end

  def handle_event("remove_tech", %{"tech" => tech}, socket) do
    updated_tech_stack = List.delete(socket.assigns.job.tech_stack, tech)
    updated_job = Map.put(socket.assigns.job, :tech_stack, updated_tech_stack)
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
    Users.list_developers(
      limit: 5,
      sort_by_country: job.country,
      sort_by_tech_stack: job.tech_stack,
      min_earnings: Money.new!(200, "USD")
    )
  end
end
