defmodule AlgoraWeb.Onboarding.OrgLive do
  require Logger
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
     |> assign(:total_steps, 2)
     |> assign(:context, context)
     |> assign(:matching_devs, get_matching_devs(context))
     |> assign(:code_valid, nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-muted/10 to-muted/20">
      <div class="flex-1 flex">
        <div class="flex-grow px-8 py-16">
          <div class="max-w-3xl mx-auto">
            <div class={["flex items-center gap-4 text-lg mb-6", @step > @total_steps && "opacity-0"]}>
              <span class="text-muted-foreground"><%= @step %> / <%= @total_steps %></span>
              <h1 class="text-lg font-semibold uppercase">Get started</h1>
            </div>

            <div class="mb-4">
              <%= render_step(assigns) %>
            </div>

            <div class="flex justify-between">
              <%= case @step do %>
                <% 1 -> %>
                  <.button phx-click="next_step" class="ml-auto bg-primary hover:bg-primary/80">
                    Next
                  </.button>
                <% 2 -> %>
                  <.button
                    phx-click="prev_step"
                    class="bg-secondary hover:bg-secondary/80 border-transparent"
                  >
                    Previous
                  </.button>
                  <.button phx-click="next_step">
                    Sign up
                  </.button>
                <% 3 -> %>
                  <.button phx-click="next_step" class="ml-auto">
                    Submit
                  </.button>
                <% _ -> %>
                  <div></div>
              <% end %>
            </div>
          </div>
        </div>
        <div class="w-1/3 border-l border-border bg-background px-6 py-4 overflow-y-auto">
          <h2 class="text-lg font-semibold uppercase mb-4">
            Matching Developers
          </h2>
          <%= if @matching_devs == [] do %>
            <p class="text-muted-foreground">Add skills to see matching developers</p>
          <% else %>
            <%= for dev <- @matching_devs do %>
              <div class="mb-6 bg-card p-4 rounded-lg border border-border">
                <div class="flex mb-2 gap-3">
                  <img src={dev.avatar_url} alt={dev.name} class="w-24 h-24 rounded-full" />
                  <div class="flex-grow">
                    <div class="flex justify-between">
                      <div>
                        <div class="font-semibold"><%= dev.name %> <%= dev.flag %></div>
                        <div class="text-sm text-muted-foreground">@<%= dev.handle %></div>
                      </div>
                      <div class="flex flex-col items-end">
                        <div class="text-muted-foreground">Earned</div>
                        <div class="font-semibold text-success font-display">
                          <%= Money.format!(dev.amount, "USD") %>
                        </div>
                      </div>
                    </div>

                    <div class="pt-3 text-sm">
                      <div class="-ml-1 text-sm flex flex-wrap gap-3">
                        <%= for skill <- dev.skills do %>
                          <span class="rounded-lg px-2 py-0.5 text-sm ring-1 ring-border bg-secondary">
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
    </div>
    """
  end

  def render_step(%{step: 1} = assigns) do
    ~H"""
    <div class="space-y-4">
      <div>
        <h2 class="text-4xl font-semibold mb-2">
          What is your tech stack?
        </h2>
        <p class="text-muted-foreground">Select the technologies you work with</p>

        <div class="mt-4">
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
            <div class="bg-primary/10 text-primary rounded-full px-4 py-2 text-sm font-semibold flex items-center">
              <%= skill %>
              <button
                phx-click="remove_skill"
                phx-value-skill={skill}
                class="ml-2 text-primary hover:text-primary/80"
              >
                ×
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <div>
        <h2 class="text-4xl font-semibold text-white mb-2">
          What are you looking to do?
        </h2>
        <p class="text-gray-400">Select all that apply</p>

        <div class="mt-4 grid grid-cols-1 gap-4">
          <%= for {intention, label} <- [
            {"bounties", "Use bounties with my own developers"},
            {"projects", "Share bounties with Algora developers"},
            {"jobs", "Hire full-time engineers"},
          ] do %>
            <div class="relative flex items-center">
              <div class="flex items-center">
                <input
                  id={"intention-#{intention}"}
                  type="checkbox"
                  phx-click="toggle_intention"
                  phx-value-intention={intention}
                  checked={intention in @context.intentions}
                  class="h-8 w-8 rounded border-input bg-background text-primary focus:ring-primary focus:ring-offset-background cursor-pointer"
                />
              </div>
              <div class="ml-3 text-base leading-6">
                <label for={"intention-#{intention}"} class="text-gray-300 cursor-pointer">
                  <%= label %>
                </label>
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
    <div class="space-y-4">
      <h2 class="text-4xl font-semibold mb-2">
        Join Algora with your team
      </h2>

      <div class="space-y-6">
        <div>
          <label class="block text-sm font-medium mb-2">Work Email</label>
          <div class="relative">
            <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
              <.icon name="tabler-mail" class="w-5 h-5 text-muted-foreground" />
            </div>
            <.input
              type="email"
              name="email"
              phx-blur="update_context"
              phx-value-field="email"
              value={@context.email}
              placeholder="you@company.com"
              class="w-full bg-background border-input pl-10"
              autocomplete="off"
              data-domain-target
              phx-hook="DeriveDomain"
            />
          </div>
        </div>
        <div>
          <label class="block text-sm font-medium">Company Domain</label>
          <p class="mt-1 text-sm text-muted-foreground">
            We will add your teammates to your organization if they sign up with a verified email address from this domain
          </p>
          <div class="mt-2 relative">
            <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
              <.icon name="tabler-at" class="w-5 h-5 text-muted-foreground" />
            </div>

            <.input
              type="text"
              name="domain"
              phx-change="update_context"
              phx-value-field="domain"
              value={@context.domain}
              placeholder="company.com"
              class="w-full bg-background border-input pl-10"
              data-domain-source
            />
          </div>

          <p class="mt-4 text-sm text-muted-foreground/75">
            By continuing, you agree to Algora's
            <.link href="/terms" class="text-primary hover:underline">Terms of Service</.link>
            and <.link href="/privacy" class="text-primary hover:underline">Privacy Policy</.link>.
          </p>
        </div>
      </div>
    </div>
    """
  end

  def render_step(%{step: 3} = assigns) do
    ~H"""
    <div class="space-y-8">
      <div>
        <h2 class="text-4xl font-semibold mb-2">
          Verify your email
        </h2>
        <p class="text-muted-foreground">
          We've sent a code to <%= @context.email %>
        </p>

        <div class="mt-6">
          <label class="block text-sm font-medium mb-2">Verification Code</label>
          <.input
            type="text"
            name="verification_code"
            phx-blur="update_context"
            phx-value-field="verification_code"
            value={@context.verification_code}
            placeholder="Enter verification code"
            class="w-full bg-background border-input text-center text-2xl tracking-widest"
          />
        </div>

        <%= if @code_valid == false do %>
          <p class="text-destructive">Please enter a valid verification code</p>
        <% end %>
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

  def handle_event("update_context", %{"field" => "email", "value" => email} = params, socket) do
    verification_token = AlgoraWeb.UserAuth.generate_login_code(email)

    # TODO: Send email
    IO.puts("========================")
    IO.puts(AlgoraWeb.UserAuth.login_email(email, verification_token))
    IO.puts("========================")

    updated_context = update_context_field(socket.assigns.context, "email", email, params)
    matching_devs = get_matching_devs(updated_context)
    {:noreply, assign(socket, context: updated_context, matching_devs: matching_devs)}
  end

  def handle_event(
        "update_context",
        %{"field" => "verification_code", "value" => token} = _params,
        socket
      ) do
    email = socket.assigns.context.email

    with {:ok, ^email} <- AlgoraWeb.UserAuth.verify_login_code(token) do
      {:noreply, socket |> redirect(to: AlgoraWeb.UserAuth.login_path(email, token))}
    else
      {:ok, _different_email} ->
        {:noreply, assign(socket, code_valid: false)}

      {:error, _reason} ->
        {:noreply, assign(socket, code_valid: false)}
    end
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
