defmodule AlgoraWeb.Project.CreateLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User

  def mount(_params, session, socket) do
    project = %{
      country: socket.assigns.current_country,
      tech_stack: ["Elixir"],
      title: "",
      visibility: :public
    }

    {:ok,
     socket
     |> assign(step: 1)
     |> assign(total_steps: 2)
     |> assign(project: project)
     |> assign(current_user: %{email: session["user_email"]})
     |> assign(matching_devs: get_matching_devs(project))}
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen flex-col bg-gradient-to-tl from-indigo-950 to-black text-white sm:flex-row">
      <div class="flex-grow bg-gray-950/25 px-4 py-8 sm:px-8 sm:py-16">
        <div class="mx-auto max-w-3xl">
          <div class="font-display mb-6 flex items-center gap-4 text-lg">
            <span class="text-gray-300">{@step} / {@total_steps}</span>
            <h1 class="text-lg font-semibold uppercase text-gray-200">Create Your Project</h1>
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
                class="rounded bg-indigo-600 px-4 py-2 font-bold text-white hover:bg-indigo-700"
              >
                Initialize Project
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <div class="font-display from-white/[5%] to-white/[2.5%] w-full overflow-y-auto border-t-2 border-gray-800 bg-gradient-to-b px-4 py-4 sm:max-h-screen sm:w-1/3 sm:border-t-0 sm:border-l-2 sm:px-8">
        <h2 class="font-display mb-4 text-lg font-semibold uppercase text-gray-200">
          Matching Developers
        </h2>
        <%= if @matching_devs == [] do %>
          <p class="text-gray-400">Add tech_stack to see matching developers</p>
        <% else %>
          <%= for dev <- @matching_devs do %>
            <div class="bg-white/[7.5%] mb-4 rounded-lg p-4">
              <div class="mb-2 flex gap-3">
                <img
                  src={dev.avatar_url}
                  alt={dev.name}
                  class="mr-3 h-16 w-16 rounded-full sm:h-24 sm:w-24"
                />
                <div class="min-w-0 flex-grow">
                  <div class="flex justify-between">
                    <div class="min-w-0">
                      <div class="font-display truncate text-base font-semibold sm:text-lg">
                        {dev.name} {dev.flag}
                      </div>
                      <div class="truncate text-sm text-gray-400">@{User.handle(dev)}</div>
                    </div>
                    <div class="ml-2 flex flex-col items-end">
                      <div class="text-sm text-gray-300">Earned</div>
                      <div class="font-display text-base font-semibold text-white sm:text-lg">
                        {Money.to_string!(dev.total_earned)}
                      </div>
                    </div>
                  </div>

                  <div class="-m-1 pt-2 text-sm sm:pt-3">
                    <div class="scrollbar-thin flex gap-2 overflow-x-auto p-1 pb-4">
                      <%= for tech <- dev.tech_stack do %>
                        <span class="whitespace-nowrap rounded-xl px-2 py-0.5 text-xs text-white ring-1 ring-white/40 sm:text-sm">
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
        What is your tech stack?
      </h2>

      <div>
        <input
          type="text"
          placeholder="Desired areas of expertise"
          class="w-full rounded-sm border border-gray-700 bg-indigo-200/5 px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
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
    </div>
    """
  end

  def render_step(%{step: 2} = assigns) do
    ~H"""
    <div>
      <h2 class="mb-4 text-2xl font-semibold">Project Details</h2>
      <div class="space-y-8">
        <div>
          <label class="mb-2 block text-sm font-medium text-gray-300">Title</label>
          <input
            type="text"
            phx-value-field="title"
            phx-blur="update_project"
            value={@project.title}
            placeholder="Looking for an Elixir developer to build and maintain a livestreaming app"
            class="w-full rounded-sm border border-gray-700 bg-indigo-200/5 px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>

        <fieldset class="mb-8">
          <legend class="mb-2 text-sm font-medium text-gray-300">Discovery</legend>
          <div class="mt-1 grid grid-cols-1 gap-y-6 sm:grid-cols-2 sm:gap-x-4">
            <label class={"#{if @project.visibility == :public, do: "border-indigo-600 bg-gray-800 ring-2 ring-indigo-600", else: "border-gray-700 bg-gray-900"} relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none"}>
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
                  <span class="flex items-center gap-2">
                    <span class="block text-sm font-medium text-gray-200">Algora Network</span>
                    <span class="text-xs font-medium text-indigo-400">15% platform fee</span>
                  </span>
                  <span class="mt-1 flex items-center text-sm text-gray-400">
                    Open to our vetted developer network
                  </span>
                  <span class="mt-6 text-sm font-medium text-gray-300">
                    Best for working with new talent quickly
                  </span>
                </span>
              </span>
              <svg
                class={"#{if @project.visibility != :public, do: "invisible"} h-5 w-5 text-indigo-600"}
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
                class={"#{if @project.visibility == :public, do: "border border-indigo-600", else: "border-2 border-transparent"} pointer-events-none absolute -inset-px rounded-lg"}
                aria-hidden="true"
              >
              </span>
            </label>

            <label class={"#{if @project.visibility == :private, do: "border-indigo-600 bg-gray-800 ring-2 ring-indigo-600", else: "border-gray-700 bg-gray-900"} relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none"}>
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
                  <span class="flex items-center gap-2">
                    <span class="block text-sm font-medium text-gray-200">Bring Your Own</span>
                    <span class="text-xs font-medium text-indigo-400">5% platform fee</span>
                  </span>
                  <span class="mt-1 flex items-center text-sm text-gray-400">
                    Invite specific developers
                  </span>
                  <span class="mt-6 text-sm font-medium text-gray-300">
                    Best for working with known teams
                  </span>
                </span>
              </span>
              <svg
                class={"#{if @project.visibility != :private, do: "invisible"} h-5 w-5 text-indigo-600"}
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
                class={"#{if @project.visibility == :private, do: "border border-indigo-600", else: "border-2 border-transparent"} pointer-events-none absolute -inset-px rounded-lg"}
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

  defp update_project_field(project, "tech_stack", _value, %{"tech" => tech}) do
    tech_stack =
      if tech in project.tech_stack,
        do: List.delete(project.tech_stack, tech),
        else: [tech | project.tech_stack]

    %{project | tech_stack: tech_stack}
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

  def handle_event("add_tech", %{"tech" => tech}, socket) do
    updated_tech_stack = Enum.uniq([tech | socket.assigns.project.tech_stack])
    updated_project = Map.put(socket.assigns.project, :tech_stack, updated_tech_stack)
    {:noreply, assign(socket, project: updated_project)}
  end

  def handle_event("remove_tech", %{"tech" => tech}, socket) do
    updated_tech_stack = List.delete(socket.assigns.project.tech_stack, tech)
    updated_project = Map.put(socket.assigns.project, :tech_stack, updated_tech_stack)
    {:noreply, assign(socket, project: updated_project)}
  end

  def handle_event("update_project", %{"field" => field, "value" => value} = params, socket) do
    updated_project = update_project_field(socket.assigns.project, field, value, params)
    matching_devs = get_matching_devs(updated_project)
    {:noreply, assign(socket, project: updated_project, matching_devs: matching_devs)}
  end

  defp next_step_label(1), do: "Project Details"
  defp next_step_label(2), do: "Collaboration"

  defp get_matching_devs(project) do
    Accounts.list_developers(
      limit: 5,
      sort_by_country: project.country,
      sort_by_tech_stack: project.tech_stack,
      earnings_gt: Money.new!(200, "USD")
    )
  end
end
