defmodule AlgoraWeb.Onboarding.OrgLive do
  use AlgoraWeb, :live_view
  alias Algora.Accounts
  alias Algora.Money

  def mount(_params, _session, socket) do
    context = %{
      country: "US",
      skills: [],
      intentions: [],
      email: "",
      domain: "",
      verification_code: ""
    }

    {:ok,
     socket
     |> assign(:step, 1)
     |> assign(:total_steps, 3)
     |> assign(:context, context)
     |> assign(:matching_devs, get_matching_devs(context))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white sm:flex">
      <div class="flex-grow p-8 max-w-3xl mx-auto">
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
            {"bounties", "Share open source bounties"},
            {"jobs", "Share full-time jobs"},
            {"projects", "Share freelancing projects"},
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
      <h2 class="text-4xl font-semibold text-white">
        Tell us about your company
      </h2>

      <div class="space-y-6">
        <div>
          <label class="block text-sm font-medium text-gray-300 mb-2">Company Domain</label>
          <input
            type="text"
            phx-blur="update_context"
            phx-value-field="domain"
            value={@context.domain}
            placeholder="company.com"
            class="w-full p-4 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-300 mb-2">Work Email</label>
          <input
            type="email"
            phx-blur="update_context"
            phx-value-field="email"
            value={@context.email}
            placeholder="you@company.com"
            class="w-full p-4 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>
      </div>
    </div>
    """
  end

  def render_step(%{step: 3} = assigns) do
    ~H"""
    <div class="space-y-8">
      <h2 class="text-4xl font-semibold text-white">
        Verify your email
      </h2>
      <p class="text-gray-400">
        We've sent a 6-digit code to <%= @context.email %>
      </p>

      <div>
        <label class="block text-sm font-medium text-gray-300 mb-2">Verification Code</label>
        <input
          type="text"
          phx-blur="update_context"
          phx-value-field="verification_code"
          value={@context.verification_code}
          maxlength="6"
          placeholder="Enter 6-digit code"
          class="w-full p-4 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 tracking-widest text-center text-2xl"
        />
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
    matching_devs = get_matching_devs(updated_context)
    {:noreply, assign(socket, context: updated_context, matching_devs: matching_devs)}
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
    matching_devs = get_matching_devs(updated_context)

    {:noreply, assign(socket, context: updated_context, matching_devs: matching_devs)}
  end

  def handle_event("handle_skill_input", _params, socket) do
    {:noreply, socket}
  end

  defp get_matching_devs(context) do
    Accounts.list_matching_devs(limit: 5, country: context.country, skills: context.skills)
  end
end
