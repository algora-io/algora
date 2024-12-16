defmodule AlgoraWeb.Onboarding.OrgLive do
  require Logger
  use AlgoraWeb, :live_view
  alias Algora.Users
  alias AlgoraWeb.Components.Wordmarks
  import Ecto.Changeset

  defmodule VerificationForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :email, :string
      field :domain, :string
    end

    @doc false
    def changeset(form, attrs) do
      form
      |> cast(attrs, [:email, :domain])
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
      |> validate_format(:domain, ~r/^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$/,
        message: "must be a valid domain"
      )
    end
  end

  def mount(_params, _session, socket) do
    steps = [:tech_stack, :verification, :preferences]

    {:ok,
     socket
     |> assign(:tech_stack, [])
     |> assign(:intentions, [])
     |> assign(:verification_form, to_form(VerificationForm.changeset(%VerificationForm{}, %{})))
     |> assign(:verification_code, nil)
     |> assign(:company_types, [])
     |> assign(:hiring_status, nil)
     |> assign(:hourly_rate_min, nil)
     |> assign(:hourly_rate_max, nil)
     |> assign(:hours_per_week, nil)
     |> assign(:step, Enum.at(steps, 1))
     |> assign(:steps, steps)
     |> assign(:code_sent?, false)
     |> assign(:code_valid?, nil)
     |> assign_matching_devs()}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-card">
      <div class="flex-1 flex">
        <div class="flex-grow px-8 py-16">
          <div class="max-w-3xl mx-auto">
            <div class="flex items-center gap-4 text-lg mb-4">
              <span class="text-muted-foreground">
                <%= Enum.find_index(@steps, &(&1 == @step)) + 1 %> / <%= length(@steps) %>
              </span>
              <h1 class="text-lg font-semibold uppercase">
                <%= if @step == Enum.at(@steps, -1) do %>
                  Last step
                <% else %>
                  Get started
                <% end %>
              </h1>
            </div>

            <div class="mb-4">
              <%= main_content(assigns) %>
            </div>

            <div class="flex justify-between">
              <%= actions(assigns) %>
            </div>
          </div>
        </div>
        <div class="w-1/3 border-l border-border bg-background px-6 py-4 overflow-y-auto h-screen">
          <%= sidebar_content(assigns) %>
          <!-- HACK: preload images to avoid layout shift -->
          <div class="fixed opacity-0">
            <%= sidebar_content(%{assigns | step: :verification}) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp actions(%{step: :tech_stack} = assigns) do
    ~H"""
    <.button phx-click="next_step" class="ml-auto">
      Next
    </.button>
    """
  end

  defp actions(%{step: :verification} = assigns) do
    ~H"""
    <.button phx-click="prev_step" variant="secondary">
      Previous
    </.button>
    <.button phx-click="next_step" variant="default">
      Next
    </.button>
    """
  end

  defp actions(%{step: :preferences} = assigns) do
    ~H"""
    <.button phx-click="prev_step" variant="secondary">
      Previous
    </.button>
    <.button phx-click="next_step" variant="default">
      Meet developers
    </.button>
    """
  end

  defp actions(assigns) do
    ~H"""
    <div></div>
    """
  end

  defp sidebar_content(%{step: :verification} = assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold uppercase mb-6">
        You're in good company
      </h2>
      <div class="grid w-full grid-cols-2 items-center justify-center gap-x-10 gap-y-16">
        <a class="relative flex items-center justify-center" href="https://console.algora.io/org/cal">
          <Wordmarks.calcom class="col-auto w-[10rem] mt-3" alt="Cal.com" />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/qdrant"
        >
          <Wordmarks.qdrant class="col-auto w-[11rem]" alt="Qdrant" />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/remotion"
        >
          <img
            src="https://algora.io/banners/remotion.png"
            alt="Remotion"
            class="saturate-0 col-auto w-full"
          />
        </a>
        <a class="relative flex items-center justify-center" href="https://console.algora.io/org/zio">
          <img
            src="https://algora.io/banners/zio.png"
            alt="ZIO"
            class="invert brightness-0 col-auto w-[10rem]"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/triggerdotdev"
        >
          <img
            src="https://algora.io/banners/triggerdotdev.png"
            alt="Trigger.dev"
            class="saturate-0 col-auto w-full"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/tembo"
        >
          <img
            src="https://algora.io/banners/tembo.png"
            alt="Tembo"
            class="saturate-0 col-auto w-[13rem]"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/maybe-finance"
        >
          <img
            src="https://algora.io/banners/maybe.png"
            alt="Maybe"
            class="saturate-0 col-auto w-full"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/golemcloud"
        >
          <Wordmarks.golemcloud class="col-auto w-full" alt="Golem Cloud" />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/aidenybai"
        >
          <img
            src="https://algora.io/banners/million.png"
            alt="Million"
            class="saturate-0 col-auto w-44"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/tailcallhq"
        >
          <Wordmarks.tailcall class="col-auto w-[10rem]" fill="white" alt="Tailcall" />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/highlight"
        >
          <img
            src="https://algora.io/banners/highlight.png"
            alt="Highlight"
            class="saturate-0 col-auto w-44"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/dittofeed"
        >
          <img
            src="https://algora.io/banners/dittofeed.png"
            alt="Dittofeed"
            class="invert brightness-0 col-auto w-40"
          />
        </a>
      </div>
    </div>
    """
  end

  defp sidebar_content(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold uppercase mb-4">
        Matching Developers
      </h2>
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
    </div>
    """
  end

  defp main_content(%{step: :tech_stack} = assigns) do
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
            id="tech-input"
            value=""
            placeholder="Elixir, Phoenix, PostgreSQL, etc."
            phx-hook="ClearInput"
            phx-keydown="add_tech"
            class="w-full bg-background border-input"
          />
        </div>

        <div class="flex flex-wrap gap-3 mt-4">
          <%= for tech <- @tech_stack do %>
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

  defp main_content(%{step: :verification, code_sent?: false} = assigns) do
    ~H"""
    <div class="space-y-4">
      <h2 class="text-4xl font-semibold mb-3">
        Join Algora with your team
      </h2>

      <.form for={@verification_form} phx-submit="submit_verification" class="space-y-6">
        <.input
          field={@verification_form[:email]}
          label="Work Email"
          icon="tabler-mail"
          type="text"
          placeholder="you@company.com"
          class="w-full bg-background border-input pl-10"
          data-domain-target
          phx-hook="DeriveDomain"
          autocomplete="email"
        />
        <.input
          field={@verification_form[:domain]}
          icon="tabler-at"
          label="Company Domain"
          helptext="We will add your teammates to your organization if they sign up with a verified email address from this domain"
          type="text"
          placeholder="company.com"
          class="w-full bg-background border-input pl-10"
          data-domain-source
        />
        <p class="mt-4 text-sm text-muted-foreground/75">
          By continuing, you agree to Algora's
          <.link href="/terms" class="text-primary hover:underline">Terms of Service</.link>
          and <.link href="/privacy" class="text-primary hover:underline">Privacy Policy</.link>.
        </p>

        <div class="flex justify-between">
          <.button type="button" phx-click="prev_step" variant="secondary">
            Previous
          </.button>
          <.button type="submit" variant="default">
            Next
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  defp main_content(%{step: :verification, code_sent?: true} = assigns) do
    ~H"""
    <div class="space-y-8">
      <div>
        <h2 class="text-4xl font-semibold mb-3">
          Verify your email
        </h2>
        <p class="text-muted-foreground">
          We've sent a code to <%= get_field(@verification_form.source, :email) %>
        </p>

        <div class="mt-6">
          <label class="block text-sm font-medium mb-2">Verification Code</label>
          <.input
            type="text"
            name="verification_code"
            phx-blur="set_field"
            phx-value-field="verification_code"
            value=""
            placeholder="Enter verification code"
            class="w-full bg-background border-input text-center text-2xl tracking-widest"
          />
        </div>

        <%= if @code_valid? == false do %>
          <p class="text-destructive">Please enter a valid verification code</p>
        <% end %>
      </div>
    </div>
    """
  end

  defp main_content(%{step: :preferences} = assigns) do
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
                  value={@hourly_rate_min}
                  placeholder="0"
                  class="w-full pl-8 bg-background border-input"
                  phx-blur="set_field"
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
                  value={@hourly_rate_max}
                  placeholder="0"
                  class="w-full pl-8 bg-background border-input"
                  phx-blur="set_field"
                  phx-value-field="hourly_rate_max"
                />
              </div>
            </div>
            <div class="flex-1">
              <label class="block text-sm font-medium mb-2">Total hours per week</label>
              <div class="relative">
                <.input
                  name="hours_per_week"
                  value={@hours_per_week}
                  placeholder="40"
                  class="w-full bg-background border-input"
                  phx-blur="set_field"
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
                @hiring_status == value && "border-primary bg-primary/10",
                @hiring_status != value && "border-border"
              ]}>
                <input
                  type="radio"
                  name="hiring_status"
                  value={value}
                  checked={@hiring_status == value}
                  phx-click="set_field"
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
                        @hiring_status != value && "invisible"
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
                type in (@company_types || []) && "border-primary bg-primary/10",
                type not in (@company_types || []) && "border-border"
              ]}>
                <input
                  type="checkbox"
                  name="company_type"
                  value={type}
                  checked={type in (@company_types || [])}
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
                        type not in (@company_types || []) && "invisible"
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

  defp assign_field(socket, "email" = _field, value, _params) do
    socket
    |> assign(:email, value)
    |> assign(:domain, value |> String.split("@") |> List.last())
  end

  defp assign_field(socket, field, value, _params) do
    socket
    |> assign(String.to_atom(field), value)
  end

  def handle_event("next_step", _, %{assigns: %{step: :tech_stack}} = socket) do
    {:noreply, assign(socket, step: :verification)}
  end

  def handle_event("next_step", _, %{assigns: %{step: :verification}} = socket) do
    {:noreply, assign(socket, step: :preferences)}
  end

  def handle_event("prev_step", _, %{assigns: %{step: :verification}} = socket) do
    {:noreply, assign(socket, step: :tech_stack)}
  end

  def handle_event("prev_step", _, %{assigns: %{step: :preferences}} = socket) do
    {:noreply, assign(socket, step: :verification)}
  end

  def handle_event("submit", _, socket) do
    # Handle context submission
    {:noreply, socket}
  end

  def handle_event("add_tech", %{"key" => key, "value" => tech}, socket)
      when key in ["Enter", ","] do
    tech = String.trim(tech)

    tech_exists? =
      Enum.any?(socket.assigns.tech_stack, fn t -> String.downcase(t) == String.downcase(tech) end)

    socket =
      if byte_size(tech) > 0 and not tech_exists? do
        socket
        |> assign(:tech_stack, socket.assigns.tech_stack ++ [tech])
        |> assign_matching_devs()
      else
        socket
      end

    {:noreply, socket |> push_event("clear-input", %{selector: "#tech-input"})}
  end

  def handle_event("add_tech", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("remove_tech", %{"tech" => tech}, socket) do
    updated_tech_stack = List.delete(socket.assigns.tech_stack, tech)
    {:noreply, assign(socket, tech_stack: updated_tech_stack)}
  end

  def handle_event("set_field", %{"field" => "verification_code", "value" => token}, socket) do
    email = get_field(socket.assigns.verification_form.source, :email)

    with {:ok, ^email} <- AlgoraWeb.UserAuth.verify_login_code(token) do
      {:noreply, socket |> redirect(to: AlgoraWeb.UserAuth.login_path(email, token))}
    else
      {:ok, _different_email} ->
        {:noreply, assign(socket, code_valid?: false)}

      {:error, _reason} ->
        {:noreply, assign(socket, code_valid?: false)}
    end
  end

  def handle_event("set_field", %{"field" => field, "value" => value} = params, socket) do
    {:noreply,
     socket
     |> assign_field(field, value, params)
     |> assign_matching_devs()}
  end

  def handle_event("toggle_intention", %{"intention" => intention}, socket) do
    updated_intentions =
      if intention in socket.assigns.intentions do
        List.delete(socket.assigns.intentions, intention)
      else
        [intention | socket.assigns.intentions]
      end

    {:noreply, assign(socket, intentions: updated_intentions)}
  end

  def handle_event("toggle_company_type", %{"type" => type}, socket) do
    current_types = socket.assigns.company_types || []

    updated_types =
      if type in current_types,
        do: List.delete(current_types, type),
        else: [type | current_types]

    {:noreply, assign(socket, company_types: updated_types)}
  end

  def handle_event("submit_verification", %{"verification_form" => params}, socket) do
    changeset =
      %VerificationForm{}
      |> VerificationForm.changeset(params)
      |> Map.put(:action, :validate)

    case changeset do
      %{valid?: true} = changeset ->
        email = get_field(changeset, :email)
        verification_token = AlgoraWeb.UserAuth.generate_login_code(email)

        # TODO: Send email
        IO.puts("========================")
        IO.puts(AlgoraWeb.UserAuth.login_email(email, verification_token))
        IO.puts("========================")

        {:noreply,
         socket
         |> assign(:verification_form, to_form(changeset))
         |> assign(:verification_code, verification_token)
         |> assign(:code_sent?, true)
         |> assign_matching_devs()}

      %{valid?: false} = changeset ->
        {:noreply, assign(socket, :verification_form, to_form(changeset))}
    end
  end

  defp assign_matching_devs(socket) do
    matching_devs =
      Users.list_developers(
        limit: 5,
        sort_by_tech_stack: socket.assigns.tech_stack,
        sort_by_country: socket.assigns.current_country,
        min_earnings: Money.new!(200, "USD")
      )

    assign(socket, :matching_devs, matching_devs)
  end
end
