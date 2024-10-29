defmodule AlgoraWeb.Onboarding.DevLive do
  use AlgoraWeb, :live_view
  alias Algora.Bounties
  alias Algora.Money

  def mount(_params, _session, socket) do
    context = %{
      country: "US",
      skills: [],
      intentions: []
    }

    bounties = Bounties.list_bounties(status: :open, limit: 5)

    {:ok,
     socket
     |> assign(:step, 1)
     |> assign(:total_steps, 2)
     |> assign(:context, context)
     |> assign(:bounties, bounties)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-tl from-indigo-950 to-black text-white sm:flex relative">
      <div class="flex-grow px-8 py-16 bg-gray-950/25">
        <div class="max-w-3xl mx-auto">
          <div class="flex items-center gap-4 text-lg mb-6 font-display">
            <span class="text-gray-300"><%= @step %> / <%= @total_steps %></span>
            <h1 class="text-lg text-gray-200 font-semibold uppercase">Get started</h1>
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
                Next
              </button>
            <% else %>
              <button
                phx-click="submit"
                class="bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-2 px-4 rounded"
              >
                Sign up
              </button>
            <% end %>
          </div>
        </div>
      </div>
      <div class="sm:w-1/3 border-l-2 border-gray-700 bg-gradient-to-b from-white/[5%] to-white/[2.5%] px-8 py-4 overflow-y-auto">
        <h2 class="text-lg text-gray-200 font-display font-semibold uppercase mb-4">
          Open Bounties
        </h2>
        <%= if @bounties == [] do %>
          <p class="text-gray-400">No open bounties available</p>
        <% else %>
          <%= for bounty <- @bounties do %>
            <div class="mb-4 bg-white/[7.5%] p-4 rounded-lg">
              <div class="flex flex-col">
                <div class="flex justify-between items-center mb-2">
                  <div class="font-mono text-2xl font-extrabold text-emerald-300">
                    <%= Money.format!(bounty.amount, bounty.currency) %>
                  </div>
                </div>
                <div class="text-sm text-gray-300 mb-1">
                  <%= bounty.task.owner %>/<%= bounty.task.repo %>#<%= bounty.task.number %>
                </div>
                <div class="text-white font-medium">
                  <%= bounty.task.title %>
                </div>
                <div class="text-xs text-gray-400 mt-2">
                  <%= Algora.Util.time_ago(bounty.inserted_at) %>
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
      <div>
        <h2 class="text-4xl font-semibold text-white mb-2">
          What is your tech stack?
        </h2>
        <p class="text-gray-400">Select the technologies you work with</p>

        <div class="mt-4">
          <input
            type="text"
            placeholder="Elixir, Phoenix, PostgreSQL, etc."
            phx-keydown="handle_skill_input"
            phx-debounce="200"
            class="w-full p-4 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>

        <div class="flex flex-wrap gap-3 mt-4">
          <%= for skill <- @context.skills do %>
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

      <div class="mt-8">
        <h2 class="text-4xl font-semibold text-white mb-2">
          What are you looking to do?
        </h2>
        <p class="text-gray-400">Select all that apply</p>

        <div class="mt-4 grid grid-cols-1 gap-4">
          <%= for {intention, label} <- [
            {"bounties", "Find open source bounties"},
            {"jobs", "Find full-time jobs"},
            {"projects", "Find freelancing projects"},
          ] do %>
            <div class="relative flex items-start">
              <div class="flex h-6 items-center">
                <input
                  type="checkbox"
                  phx-click="toggle_intention"
                  phx-value-intention={intention}
                  checked={intention in @context.intentions}
                  class="h-4 w-4 rounded border-gray-700 bg-gray-800 text-indigo-600 focus:ring-indigo-600 focus:ring-offset-gray-900"
                />
              </div>
              <div class="ml-3 text-sm leading-6">
                <label class="text-gray-300"><%= label %></label>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def render_step(%{step: 2} = assigns) do
    ~H"""
    <div class="space-y-8">
      <h2 class="text-4xl font-semibold text-white"></h2>

      <div class="space-y-6">
        <.link
          href={Algora.Github.authorize_url()}
          rel="noopener"
          class="mt-8 w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-400"
        >
          <AlgoraWeb.Components.Icons.github class="w-5 h-5 mr-2" /> Sign in with GitHub
        </.link>
      </div>
    </div>
    """
  end

  defp update_context_field(context, "skills", _value, %{"skill" => skill}) do
    skills =
      if skill in context.skills,
        do: List.delete(context.skills, skill),
        else: [skill | context.skills]

    %{context | skills: skills}
  end

  defp update_context_field(context, "email" = _field, value, _params) do
    domain = value |> String.split("@") |> List.last()

    context
    |> Map.put(:email, value)
    |> Map.put(:domain, domain)
  end

  defp update_context_field(context, field, value, _params) do
    Map.put(context, String.to_atom(field), value)
  end

  def handle_event("next_step", _, socket) do
    {:noreply, assign(socket, step: socket.assigns.step + 1)}
  end

  def handle_event("prev_step", _, socket) do
    {:noreply, assign(socket, step: socket.assigns.step - 1)}
  end

  def handle_event("submit", _, socket) do
    # Handle context submission
    {:noreply, socket}
  end

  def handle_event("add_skill", %{"skill" => skill}, socket) do
    updated_skills = [skill | socket.assigns.context.skills] |> Enum.uniq()
    updated_context = Map.put(socket.assigns.context, :skills, updated_skills)
    {:noreply, assign(socket, context: updated_context)}
  end

  def handle_event("remove_skill", %{"skill" => skill}, socket) do
    updated_skills = List.delete(socket.assigns.context.skills, skill)
    updated_context = Map.put(socket.assigns.context, :skills, updated_skills)
    {:noreply, assign(socket, context: updated_context)}
  end

  def handle_event("update_context", %{"field" => field, "value" => value} = params, socket) do
    updated_context = update_context_field(socket.assigns.context, field, value, params)
    {:noreply, assign(socket, context: updated_context)}
  end

  def handle_event("toggle_intention", %{"intention" => intention}, socket) do
    updated_intentions =
      if intention in socket.assigns.context.intentions do
        List.delete(socket.assigns.context.intentions, intention)
      else
        [intention | socket.assigns.context.intentions]
      end

    updated_context = Map.put(socket.assigns.context, :intentions, updated_intentions)
    {:noreply, assign(socket, context: updated_context)}
  end

  def handle_event("handle_skill_input", %{"key" => "Enter", "value" => skill}, socket)
      when byte_size(skill) > 0 do
    updated_skills = [String.trim(skill) | socket.assigns.context.skills] |> Enum.uniq()
    updated_context = Map.put(socket.assigns.context, :skills, updated_skills)
    {:noreply, assign(socket, context: updated_context)}
  end

  def handle_event("handle_skill_input", _params, socket) do
    {:noreply, socket}
  end
end
