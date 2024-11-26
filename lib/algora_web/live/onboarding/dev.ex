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

    bounties =
      Bounties.list_bounties(
        status: :completed,
        limit: 50,
        solver_country: "US",
        sort_by: :amount
      )
      |> Enum.uniq_by(& &1.solver.id)

    dbg(bounties)

    {:ok,
     socket
     |> assign(:step, 1)
     |> assign(:total_steps, 2)
     |> assign(:context, context)
     |> assign(:bounties, bounties)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-card">
      <div class="flex-1 flex">
        <div class="flex-grow px-8 py-16">
          <div class="max-w-3xl mx-auto">
            <div class="flex items-center gap-4 text-lg mb-6">
              <span class="text-muted-foreground">
                <%= @step %> / <%= @total_steps %>
              </span>
              <h1 class="text-lg font-semibold uppercase">Get started</h1>
            </div>

            <div class="mb-4">
              <%= render_step(assigns) %>
            </div>

            <div class="flex justify-between">
              <%= if @step > 1 do %>
                <.button phx-click="prev_step" variant="secondary">
                  Previous
                </.button>
              <% else %>
                <div></div>
              <% end %>
              <%= if @step < @total_steps do %>
                <.button phx-click="next_step" variant="default">
                  Next
                </.button>
              <% else %>
                <.button>
                  <.link
                    href={Algora.Github.authorize_url()}
                    rel="noopener"
                    class="inline-flex items-center"
                  >
                    <.icon name="tabler-brand-github" class="w-5 h-5 mr-2" /> Sign in with GitHub
                  </.link>
                </.button>
              <% end %>
            </div>
          </div>
        </div>
        <div class="w-1/3 border-l border-border bg-background px-6 py-4 overflow-y-auto h-screen">
          <h2 class="text-lg font-semibold uppercase mb-4">
            Recently Completed Bounties
          </h2>
          <%= if @bounties == [] do %>
            <p class="text-muted-foreground">No completed bounties available</p>
          <% else %>
            <%= for bounty <- @bounties do %>
              <div class="mb-4 bg-card p-4 rounded-lg border border-border">
                <div class="flex gap-4">
                  <div class="flex-1">
                    <div class="font-mono text-2xl font-extrabold text-success mb-2">
                      <%= Money.format!(bounty.amount, bounty.currency) %>
                    </div>
                    <div class="text-sm text-muted-foreground mb-1">
                      <%= bounty.ticket.owner %>/<%= bounty.ticket.repo %>#<%= bounty.ticket.number %>
                    </div>
                    <div class="font-medium">
                      <%= bounty.ticket.title %>
                    </div>
                    <div class="text-xs text-muted-foreground mt-2">
                      <%= Algora.Util.time_ago(bounty.inserted_at) %>
                    </div>
                  </div>

                  <div class="w-32 flex flex-col items-center border-l border-border pl-4">
                    <h3 class="text-xs font-medium text-muted-foreground uppercase mb-3">
                      Awarded to
                    </h3>
                    <img
                      src={bounty.solver.avatar_url}
                      class="w-16 h-16 rounded-full mb-2"
                      alt={bounty.solver.name}
                    />
                    <div class="text-sm font-medium text-center">
                      <%= bounty.solver.name %>
                      <span class="ml-1">
                        <%= Algora.Misc.CountryEmojis.get(bounty.solver.country, "🌎") %>
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def render_step(%{step: 1} = assigns) do
    ~H"""
    <div class="space-y-8">
      <div>
        <h2 class="text-4xl font-semibold mb-2">
          What is your tech stack?
        </h2>
        <p class="text-muted-foreground">Select the technologies you work with</p>

        <div class="relative mt-1">
          <.input
            type="text"
            name="skill_input"
            value=""
            placeholder="Elixir, Phoenix, PostgreSQL, etc."
            phx-keydown="handle_skill_input"
            phx-debounce="200"
            class="w-full bg-background border-input"
          />
        </div>

        <div class="flex flex-wrap gap-3 mt-4">
          <%= for skill <- @context.skills do %>
            <div class="bg-success/10 text-success rounded-lg px-3 py-1.5 text-sm font-semibold flex items-center">
              <%= skill %>
              <button
                phx-click="remove_skill"
                phx-value-skill={skill}
                class="ml-2 text-success hover:text-success/80"
              >
                ×
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <div class="mt-8">
        <h2 class="text-4xl font-semibold mb-2">
          What are you looking to do?
        </h2>
        <p class="text-muted-foreground">Select all that apply</p>

        <div class="-ml-4 mt-2">
          <%= for {intention, label, description, icon} <- [
            {"bounties", "Solve Bounties", "Work on open source issues and earn rewards", "tabler-diamond"},
            {"jobs", "Find Full-time Work", "Get matched with companies hiring developers", "tabler-briefcase"},
            {"projects", "Freelance Work", "Take on flexible contract-based projects", "tabler-clock"}
          ] do %>
            <label class="p-4 flex items-center gap-3 rounded-lg hover:bg-muted cursor-pointer">
              <input
                type="checkbox"
                phx-click="toggle_intention"
                phx-value-intention={intention}
                checked={intention in @context.intentions}
                class="h-10 w-10 rounded border-input bg-background text-primary focus:ring-primary focus:ring-offset-background"
              />
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <.icon name={icon} class="w-5 h-5 text-muted-foreground" />
                  <span class="font-medium"><%= label %></span>
                </div>
                <p class="text-sm text-muted-foreground mt-0.5">
                  <%= description %>
                </p>
              </div>
            </label>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def render_step(%{step: 2} = assigns) do
    ~H"""
    <div class="space-y-8">
      <div>
        <h2 class="text-4xl font-semibold mb-2">
          Connect your GitHub account
        </h2>
        <p class="text-muted-foreground mb-6">
          Sign in with GitHub to join our developer community and start earning bounties.
        </p>

        <p class="text-sm text-muted-foreground/75">
          By continuing, you agree to Algora's
          <.link href="/terms" class="text-primary hover:underline">Terms of Service</.link>
          and <.link href="/privacy" class="text-primary hover:underline">Privacy Policy</.link>.
        </p>
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
