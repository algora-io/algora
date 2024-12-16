defmodule AlgoraWeb.Onboarding.OrgLive do
  require Logger
  use AlgoraWeb, :live_view
  alias Algora.Users

  def mount(_params, _session, socket) do
    context = %{
      country: socket.assigns.current_country,
      tech_stack: [],
      intentions: [],
      email: "",
      domain: "",
      verification_code: "",
      code_sent?: false,
      company_types: [],
      hiring_status: nil,
      hourly_rate_min: nil,
      hourly_rate_max: nil,
      hours_per_week: nil
    }

    {:ok,
     socket
     |> assign(:step, 1)
     |> assign(:total_steps, 3)
     |> assign(:context, context)
     |> assign(:matching_devs, get_matching_devs(context))
     |> assign(:code_valid, nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-card">
      <div class="flex-1 flex">
        <div class="flex-grow px-8 py-16">
          <div class="max-w-3xl mx-auto">
            <div class="flex items-center gap-4 text-lg mb-4">
              <span class="text-muted-foreground">
                <%= min(@step, @total_steps) %> / <%= @total_steps %>
              </span>
              <h1 class="text-lg font-semibold uppercase">
                <%= case @step do %>
                  <% 3 -> %>
                    Last step
                  <% _ -> %>
                    Get started
                <% end %>
              </h1>
            </div>

            <div class="mb-4">
              <%= render_step(assigns) %>
            </div>

            <div class="flex justify-between">
              <%= case @step do %>
                <% 1 -> %>
                  <.button phx-click="next_step" class="ml-auto">
                    Next
                  </.button>
                <% 2 -> %>
                  <.button phx-click="prev_step" variant="secondary">
                    Previous
                  </.button>
                  <.button phx-click="next_step" variant="default">
                    Next
                  </.button>
                <% 3 -> %>
                  <.button phx-click="prev_step" variant="secondary">
                    Previous
                  </.button>
                  <.button phx-click="next_step" variant="default">
                    Meet developers
                  </.button>
                <% _ -> %>
                  <div></div>
              <% end %>
            </div>
          </div>
        </div>
        <div class="w-1/3 border-l border-border bg-background px-6 py-4 overflow-y-auto h-screen">
          <div class={
            classes(
              hidden: @step != 2,
              block: @step == 2
            )
          }>
            <h2 class="text-lg font-semibold uppercase mb-6">
              You're in good company
            </h2>
            <div class="grid w-full grid-cols-2 items-center justify-center gap-x-10 gap-y-16 saturate-0">
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/cal"
              >
                <img
                  src="https://algora.io/banners/calcom.png"
                  alt="Cal.com"
                  class="col-auto w-[10rem] mt-3"
                />
              </a>
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/qdrant"
              >
                <img
                  src="https://algora.io/banners/qdrant.png"
                  alt="Qdrant"
                  class="col-auto w-[11rem]"
                />
              </a>
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/remotion"
              >
                <img
                  src="https://algora.io/banners/remotion.png"
                  alt="Remotion"
                  class="col-auto w-full"
                />
              </a>
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/zio"
              >
                <img src="https://algora.io/banners/zio.png" alt="ZIO" class="col-auto w-[13rem]" />
              </a>
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/triggerdotdev"
              >
                <img
                  src="https://algora.io/banners/triggerdotdev.png"
                  alt="Trigger.dev"
                  class="col-auto w-full"
                />
              </a>
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/tembo"
              >
                <img src="https://algora.io/banners/tembo.png" alt="Tembo" class="col-auto w-[13rem]" />
              </a>
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/maybe-finance"
              >
                <img src="https://algora.io/banners/maybe.png" alt="Maybe" class="col-auto w-full" />
              </a>
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/golemcloud"
              >
                <img
                  src="https://algora.io/banners/golem.png"
                  alt="Golem Cloud"
                  class="col-auto w-full"
                />
              </a>
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/aidenybai"
              >
                <img src="https://algora.io/banners/million.png" alt="Million" class="col-auto w-36" />
              </a>
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/tailcallhq"
              >
                <AlgoraWeb.Components.Wordmarks.tailcall class="col-auto w-[13rem]" />
              </a>
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/highlight"
              >
                <img
                  src="https://algora.io/banners/highlight.png"
                  alt="Highlight"
                  class="col-auto w-44"
                />
              </a>
              <a
                class="relative flex items-center justify-center"
                href="https://console.algora.io/org/dittofeed"
              >
                <img
                  src="https://algora.io/banners/dittofeed.png"
                  alt="Dittofeed"
                  class="col-auto w-40"
                />
              </a>
            </div>
          </div>
          <div
            div
            class={
              classes(
                hidden: @step == 2,
                block: @step != 2
              )
            }
          >
            <h2 class="text-lg font-semibold uppercase mb-4">
              Matching Developers
            </h2>
            <%= if @matching_devs == [] do %>
              <p class="text-muted-foreground">Add tech stack to see matching developers</p>
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
                            <%= Money.to_string!(dev.total_earned) %>
                          </div>
                        </div>
                      </div>

                      <div class="pt-3 text-sm">
                        <div class="-ml-1 text-sm flex flex-wrap gap-3">
                          <%= for tech <- dev.tech_stack do %>
                            <span class="rounded-lg px-2 py-0.5 text-sm ring-1 ring-border bg-secondary">
                              <%= tech %>
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
    </div>
    """
  end

  def render_step(%{step: 1} = assigns) do
    ~H"""
    <div>
      <div>
        <h2 class="text-4xl font-semibold mb-3">
          What is your tech stack?
        </h2>
        <p class="text-muted-foreground">Select the technologies you work with</p>

        <div class="mt-4">
          <.input
            type="text"
            name="tech_input"
            value=""
            placeholder="Elixir, Phoenix, PostgreSQL, etc."
            phx-keydown="handle_tech_input"
            phx-debounce="200"
            class="w-full bg-background border-input"
          />
        </div>

        <div class="flex flex-wrap gap-3 mt-4">
          <%= for tech <- @context.tech_stack do %>
            <div class="bg-success/10 text-success rounded-lg px-3 py-1.5 text-sm font-semibold flex items-center">
              <%= tech %>
              <button
                phx-click="remove_tech"
                phx-value-tech={tech}
                class="ml-2 text-success hover:text-success/80"
              >
                ×
              </button>
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
      <h2 class="text-4xl font-semibold mb-3">
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

  def render_step(%{step: 2, code_sent?: true} = assigns) do
    ~H"""
    <div class="space-y-8">
      <div>
        <h2 class="text-4xl font-semibold mb-3">
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

  def render_step(%{step: 3} = assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h2 class="text-4xl font-semibold">
          Let's personalize your experience
        </h2>
        <p class="text-muted-foreground mt-2">
          We'll use this information to match you with the best developers
        </p>
      </div>

      <div class="space-y-8">
        <div>
          <label class="block text-lg font-semibold mb-1">Hourly Rate (USD)</label>
          <p class="text-muted-foreground mb-3 text-sm">
            Enter the range of hourly rates you're looking for
          </p>
          <div class="flex items-center gap-4">
            <div class="flex-1">
              <label class="block text-sm font-medium mb-2">Min</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                  <span class="text-muted-foreground">$</span>
                </div>
                <.input
                  name="hourly_rate_min"
                  value={@context.hourly_rate_min}
                  placeholder="0"
                  class="w-full pl-8 bg-background border-input"
                  phx-blur="update_context"
                  phx-value-field="hourly_rate_min"
                />
              </div>
            </div>
            <div class="flex-1">
              <label class="block text-sm font-medium mb-2">Max</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                  <span class="text-muted-foreground">$</span>
                </div>
                <.input
                  name="hourly_rate_max"
                  value={@context.hourly_rate_max}
                  placeholder="0"
                  class="w-full pl-8 bg-background border-input"
                  phx-blur="update_context"
                  phx-value-field="hourly_rate_max"
                />
              </div>
            </div>
            <div class="flex-1">
              <label class="block text-sm font-medium mb-2">Total hours per week</label>
              <div class="relative">
                <.input
                  name="hours_per_week"
                  value={@context.hours_per_week}
                  placeholder="40"
                  class="w-full bg-background border-input"
                  phx-blur="update_context"
                  phx-value-field="hours_per_week"
                />
              </div>
            </div>
          </div>
        </div>

        <div>
          <label class="block text-lg font-semibold mb-1">Are you hiring full-time?</label>
          <p class="text-muted-foreground mb-3 text-sm">
            We will match you with developers who are looking for full-time work
          </p>
          <div class="grid grid-cols-2 gap-4">
            <%= for {value, label} <- [{"yes", "Yes"}, {"no", "No"}] do %>
              <label class={[
                "relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none",
                "bg-background border-2 hover:border-primary hover:bg-primary/10 transition-all duration-200",
                @context.hiring_status == value && "border-primary bg-primary/10",
                @context.hiring_status != value && "border-border"
              ]}>
                <input
                  type="radio"
                  name="hiring_status"
                  value={value}
                  checked={@context.hiring_status == value}
                  phx-click="update_context"
                  phx-value-field="hiring_status"
                  phx-value-value={value}
                  class="sr-only"
                />
                <span class="flex flex-1 items-center justify-between">
                  <span class="text-sm font-medium"><%= label %></span>
                  <.icon
                    name="tabler-check"
                    class={
                      classes([
                        "size-5 text-primary",
                        @context.hiring_status != value && "invisible"
                      ])
                    }
                  />
                </span>
              </label>
            <% end %>
          </div>
        </div>

        <div>
          <label class="block text-lg font-semibold mb-1">
            Which of the following best describes you?
          </label>
          <p class="text-muted-foreground mb-3 text-sm">
            Select all that apply
          </p>
          <div class="grid grid-cols-2 gap-4">
            <%= for {type, label} <- [
                  {"opensource", "Open source company"},
                  {"closedsource", "Closed source company"},
                  {"agency", "Agency / consultancy / studio"},
                  {"nonprofit", "Non-profit / FOSS"}
                ] do %>
              <label class={[
                "relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none",
                "bg-background border-2 hover:border-primary hover:bg-primary/10 transition-all duration-200",
                type in (@context.company_types || []) && "border-primary bg-primary/10",
                type not in (@context.company_types || []) && "border-border"
              ]}>
                <input
                  type="checkbox"
                  name="company_type"
                  value={type}
                  checked={type in (@context.company_types || [])}
                  phx-click="toggle_company_type"
                  phx-value-type={type}
                  class="sr-only"
                />
                <span class="flex flex-1 items-center justify-between">
                  <span class="text-sm font-medium"><%= label %></span>
                  <.icon
                    name="tabler-check"
                    class={
                      classes([
                        "size-5 text-primary",
                        type not in (@context.company_types || []) && "invisible"
                      ])
                    }
                  />
                </span>
              </label>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp update_context_field(context, "tech_stack", _value, %{"tech" => tech}) do
    tech_stack =
      if tech in context.tech_stack,
        do: List.delete(context.tech_stack, tech),
        else: [tech | context.tech_stack]

    %{context | tech_stack: tech_stack}
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

  def handle_event("add_tech", %{"tech" => tech}, socket) do
    updated_tech_stack = [tech | socket.assigns.context.tech_stack] |> Enum.uniq()
    updated_context = Map.put(socket.assigns.context, :tech_stack, updated_tech_stack)
    {:noreply, assign(socket, context: updated_context)}
  end

  def handle_event("remove_tech", %{"tech" => tech}, socket) do
    updated_tech_stack = List.delete(socket.assigns.context.tech_stack, tech)
    updated_context = Map.put(socket.assigns.context, :tech_stack, updated_tech_stack)
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

    {:noreply,
     socket
     |> assign(:code_sent?, true)
     |> assign(:context, updated_context)
     |> assign(:matching_devs, matching_devs)}
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

  def handle_event("handle_tech_input", %{"key" => "Enter", "value" => tech}, socket)
      when byte_size(tech) > 0 do
    updated_tech_stack = [String.trim(tech) | socket.assigns.context.tech_stack] |> Enum.uniq()
    updated_context = Map.put(socket.assigns.context, :tech_stack, updated_tech_stack)
    matching_devs = get_matching_devs(updated_context)

    {:noreply, assign(socket, context: updated_context, matching_devs: matching_devs)}
  end

  def handle_event("handle_tech_input", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle_company_type", %{"type" => type}, socket) do
    current_types = socket.assigns.context.company_types || []

    updated_types =
      if type in current_types,
        do: List.delete(current_types, type),
        else: [type | current_types]

    updated_context = Map.put(socket.assigns.context, :company_types, updated_types)
    {:noreply, assign(socket, context: updated_context)}
  end

  defp get_matching_devs(context) do
    Users.list_developers(
      limit: 5,
      sort_by_country: context.country,
      sort_by_tech_stack: context.tech_stack
    )
  end
end
