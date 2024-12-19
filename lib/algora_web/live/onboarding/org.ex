defmodule AlgoraWeb.Onboarding.OrgLive do
  require Logger
  use AlgoraWeb, :live_view
  alias Algora.Users
  alias AlgoraWeb.Components.Wordmarks
  import Ecto.Changeset
  alias Algora.Factory
  use LiveSvelte.Components

  # === SCHEMAS === #

  defmodule TechStackForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :tech_stack, {:array, :string}
    end

    def init() do
      to_form(TechStackForm.changeset(%TechStackForm{}, %{tech_stack: []}))
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:tech_stack])
      |> validate_length(:tech_stack, min: 1, message: "Please select at least one technology")
    end
  end

  defmodule EmailForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :email, :string
      field :domain, :string
    end

    def init() do
      to_form(EmailForm.changeset(%EmailForm{}, %{}))
    end

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

  defmodule VerificationForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :code, :string
    end

    def init() do
      to_form(VerificationForm.changeset(%VerificationForm{}, %{}))
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:code])
      |> validate_required([:code])
    end
  end

  defmodule PreferencesForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :hourly_rate_min, :integer
      field :hourly_rate_max, :integer
      field :hours_per_week, :integer
      field :hiring, :boolean
      field :company_types, {:array, :string}
    end

    def hiring_options() do
      [{"Yes", "true"}, {"No", "false"}]
    end

    def company_types_options() do
      [
        {"Open source company", "open_source"},
        {"Closed source company", "closed_source"},
        {"Agency / consultancy / studio", "agency"},
        {"Non-profit / FOSS", "nonprofit"}
      ]
    end

    def init() do
      to_form(PreferencesForm.changeset(%PreferencesForm{}, %{company_types: []}))
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [
        :hourly_rate_min,
        :hourly_rate_max,
        :hours_per_week,
        :hiring,
        :company_types
      ])
      |> validate_required([:hourly_rate_min], message: "Please enter a minimum hourly rate")
      |> validate_required([:hourly_rate_max], message: "Please enter a maximum hourly rate")
      |> validate_required([:hours_per_week], message: "Please enter a number of hours per week")
      |> validate_required([:hiring], message: "Please select a hiring status")
      |> validate_number(:hourly_rate_min, greater_than: 0)
      |> validate_number(:hourly_rate_max, greater_than: 0)
      |> validate_number(:hours_per_week, greater_than: 0)
      |> validate_length(:company_types,
        min: 1,
        message: "Please select at least one company type"
      )
      |> validate_subset(
        :company_types,
        PreferencesForm.company_types_options() |> Enum.map(&elem(&1, 1))
      )
      |> validate_rate_range()
    end

    defp validate_rate_range(changeset) do
      min_rate = get_field(changeset, :hourly_rate_min)
      max_rate = get_field(changeset, :hourly_rate_max)

      if min_rate && max_rate && min_rate > max_rate do
        add_error(changeset, :hourly_rate_min, "must be less than maximum rate")
      else
        changeset
      end
    end
  end

  # === LIFECYCLE === #

  def mount(_params, _session, socket) do
    steps = [:tech_stack, :email, :preferences]

    {:ok,
     socket
     |> assign(:tech_stack_form, TechStackForm.init())
     |> assign(:email_form, EmailForm.init())
     |> assign(:verification_form, VerificationForm.init())
     |> assign(:preferences_form, PreferencesForm.init())
     |> assign(:step, Enum.at(steps, 0))
     |> assign(:steps, steps)
     |> assign(:code_sent?, false)
     |> assign(:code_valid?, nil)
     |> assign_matching_devs()}
  end

  # === EVENT HANDLERS === #

  def handle_event("prev_step", _, socket) do
    current_step_index = Enum.find_index(socket.assigns.steps, &(&1 == socket.assigns.step))
    prev_step = Enum.at(socket.assigns.steps, current_step_index - 1)
    {:noreply, assign(socket, :step, prev_step)}
  end

  def handle_event("submit_tech_stack", %{"tech_stack_form" => params}, socket) do
    changeset =
      %TechStackForm{}
      |> TechStackForm.changeset(%{tech_stack: Jason.decode!(params["tech_stack"])})
      |> Map.put(:action, :validate)

    case changeset do
      %{valid?: true} ->
        {:noreply,
         socket
         |> assign(:tech_stack_form, to_form(changeset))
         |> assign_matching_devs()
         |> assign(step: :email)}

      %{valid?: false} ->
        {:noreply, assign(socket, tech_stack_form: to_form(changeset))}
    end
  end

  def handle_event("submit_email", %{"email_form" => params}, socket) do
    changeset =
      %EmailForm{}
      |> EmailForm.changeset(params)
      |> Map.put(:action, :validate)

    case changeset do
      %{valid?: true} = changeset ->
        email = get_field(changeset, :email)
        login_code = AlgoraWeb.UserAuth.generate_login_code(email)

        # TODO: Send email
        Logger.info("Login code for #{email}: #{login_code}")

        {:noreply,
         socket
         |> assign(:email_form, to_form(changeset))
         |> assign(:code_sent?, true)
         |> assign_matching_devs()}

      %{valid?: false} = changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset))}
    end
  end

  def handle_event("submit_preferences", %{"preferences_form" => params}, socket) do
    changeset =
      %PreferencesForm{}
      |> PreferencesForm.changeset(params)
      |> Map.put(:action, :validate)

    case changeset do
      %{valid?: true} ->
        # Get all the form data
        email = get_field(socket.assigns.email_form.source, :email)
        domain = get_field(socket.assigns.email_form.source, :domain)
        tech_stack = get_field(socket.assigns.tech_stack_form.source, :tech_stack)
        login_code = get_field(socket.assigns.verification_form.source, :code)
        preferences = changeset.changes

        # TODO: call async and handle errors
        metadata = Algora.Crawler.fetch_user_metadata(email)

        user_handle =
          email
          |> String.split("@")
          |> List.first()
          |> String.replace(~r/[^a-zA-Z0-9]/, "")
          |> String.downcase()

        org_name =
          case get_in(metadata, [:org, :display_name]) do
            nil ->
              domain
              |> String.split(".")
              |> List.first()
              |> String.capitalize()

            name ->
              name
          end

        org_handle =
          case get_in(metadata, [:org, :handle]) do
            nil ->
              domain
              |> String.split(".")
              |> List.first()
              |> String.downcase()

            handle ->
              handle
          end

        # TODO: use context functions instead of Factory
        # TODO: generate nicer handles or let the user choose

        org =
          Factory.upsert!(:organization, [:email], %{
            # TODO: unset email
            email: "admin@#{domain}",
            display_name: org_name,
            bio:
              get_in(metadata, [:org, :bio]) ||
                get_in(metadata, [:org, :og_description]) ||
                get_in(metadata, [:org, :og_title]),
            avatar_url:
              get_in(metadata, [:org, :avatar_url]) || get_in(metadata, [:org, :favicon_url]),
            handle: org_handle <> "-" <> String.slice(Nanoid.generate(), 0, 4),
            domain: domain,
            og_title: get_in(metadata, [:org, :og_title]),
            og_image_url: get_in(metadata, [:org, :og_image_url]),
            tech_stack: tech_stack,
            hourly_rate_min: Money.new!(preferences.hourly_rate_min, :USD),
            hourly_rate_max: Money.new!(preferences.hourly_rate_max, :USD),
            hours_per_week: preferences.hours_per_week,
            website_url: get_in(metadata, [:org, :website_url]),
            twitter_url: get_in(metadata, [:org, :socials, :twitter]),
            github_url: get_in(metadata, [:org, :socials, :github]),
            youtube_url: get_in(metadata, [:org, :socials, :youtube]),
            twitch_url: get_in(metadata, [:org, :socials, :twitch]),
            discord_url: get_in(metadata, [:org, :socials, :discord]),
            slack_url: get_in(metadata, [:org, :socials, :slack]),
            linkedin_url: get_in(metadata, [:org, :socials, :linkedin])
          })

        user =
          Factory.upsert!(:user, [:email], %{
            email: email,
            display_name: user_handle,
            avatar_url: get_in(metadata, [:avatar_url]),
            handle: user_handle <> "-" <> String.slice(Nanoid.generate(), 0, 4),
            tech_stack: tech_stack,
            last_context: org.handle
          })

        _member =
          Factory.upsert!(:member, [:user_id, :org_id], %{
            user_id: user.id,
            org_id: org.id,
            role: :admin
          })

        _contract =
          Factory.insert!(
            :contract,
            %{
              status: :draft,
              client_id: org.id,
              hourly_rate_min: Money.new!(preferences.hourly_rate_min, :USD),
              hourly_rate_max: Money.new!(preferences.hourly_rate_max, :USD),
              hours_per_week: preferences.hours_per_week
            }
          )

        {:noreply,
         socket
         |> put_flash(:info, "Welcome to Algora!")
         |> redirect(to: AlgoraWeb.UserAuth.login_path(email, login_code))}

      %{valid?: false} ->
        {:noreply, assign(socket, preferences_form: to_form(changeset))}
    end
  end

  def handle_event("submit_verification", %{"verification_form" => params}, socket) do
    changeset =
      %VerificationForm{}
      |> VerificationForm.changeset(params)
      |> Map.put(:action, :validate)

    case changeset do
      %{valid?: true} = changeset ->
        code = get_field(changeset, :code)
        email = get_field(socket.assigns.email_form.source, :email)

        with {:ok, ^email} <- AlgoraWeb.UserAuth.verify_login_code(code) do
          {:noreply,
           socket
           |> assign(:verification_form, to_form(changeset))
           |> assign(step: :preferences)}
        else
          {:ok, _different_email} ->
            {:noreply,
             socket
             |> assign(:verification_form, to_form(changeset))
             |> assign(:code_valid?, false)}

          {:error, _reason} ->
            {:noreply,
             socket
             |> assign(:verification_form, to_form(changeset))
             |> assign(:code_valid?, false)}
        end

      %{valid?: false} = changeset ->
        {:noreply, assign(socket, :verification_form, to_form(changeset))}
    end
  end

  def handle_event("tech_stack_changed", %{"tech_stack" => tech_stack}, socket) do
    changeset = %TechStackForm{} |> TechStackForm.changeset(%{tech_stack: tech_stack})

    {:noreply,
     socket
     |> assign(:tech_stack_form, to_form(changeset))
     |> assign_matching_devs()}
  end

  # === PRIVATE HELPERS === #

  defp assign_matching_devs(socket) do
    tech_stack = get_field(socket.assigns.tech_stack_form.source, :tech_stack)

    matching_devs =
      Users.list_developers(
        limit: 5,
        sort_by_tech_stack: tech_stack,
        sort_by_country: socket.assigns.current_country,
        min_earnings: Money.new!(200, "USD")
      )

    assign(socket, :matching_devs, matching_devs)
  end

  # === TEMPLATES === #

  defp main_content(%{step: :tech_stack} = assigns) do
    ~H"""
    <div>
      <.form
        for={@tech_stack_form}
        phx-submit="submit_tech_stack"
        class="space-y-6"
        onkeydown="if(event.key === 'Enter') { event.preventDefault(); return false; }"
      >
        <div>
          <h2 class="text-4xl font-semibold mb-3">
            What is your tech stack?
          </h2>
          <p class="text-muted-foreground">
            Enter a comma-separated list of technologies you work with
          </p>

          <.TechStack
            class="mt-4"
            props={%{tech_stack: get_field(@tech_stack_form.source, :tech_stack) || []}}
            socket={@socket}
          />

          <.error :for={msg <- @tech_stack_form[:tech_stack].errors |> Enum.map(&translate_error(&1))}>
            <%= msg %>
          </.error>
        </div>

        <div class="flex justify-end">
          <.button type="submit">
            Next <.icon name="tabler-arrow-right" class="ml-2 size-4" />
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  defp main_content(%{step: :email, code_sent?: false} = assigns) do
    ~H"""
    <div class="space-y-4">
      <h2 class="text-4xl font-semibold mb-3">
        Join Algora with your team
      </h2>

      <.form for={@email_form} phx-submit="submit_email" class="space-y-6">
        <.input
          field={@email_form[:email]}
          label="Work Email"
          icon="tabler-mail"
          type="text"
          placeholder="you@company.com"
          class="w-full bg-background border-input"
          data-domain-target
          phx-hook="DeriveDomain"
          autocomplete="email"
        />
        <.input
          field={@email_form[:domain]}
          icon="tabler-at"
          label="Company Domain"
          helptext="We will add your teammates to your organization if they sign up with a verified email address from this domain"
          type="text"
          placeholder="company.com"
          class="w-full bg-background border-input"
          data-domain-source
        />
        <p class="mt-4 text-sm text-muted-foreground/75">
          By continuing, you agree to Algora's
          <.link href="/terms" class="text-primary hover:underline">Terms of Service</.link>
          and <.link href="/privacy" class="text-primary hover:underline">Privacy Policy</.link>.
        </p>

        <div class="flex justify-between">
          <.button type="button" phx-click="prev_step" variant="secondary">
            <.icon name="tabler-arrow-left" class="mr-2 size-4" /> Previous
          </.button>
          <.button type="submit">
            Next <.icon name="tabler-arrow-right" class="ml-2 size-4" />
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  defp main_content(%{step: :email, code_sent?: true} = assigns) do
    ~H"""
    <div class="space-y-8">
      <div>
        <h2 class="text-4xl font-semibold mb-3">
          Verify your email
        </h2>
        <p class="text-muted-foreground">
          We've sent a code to <%= get_field(@email_form.source, :email) %>
        </p>

        <div class="mt-6">
          <.form for={@verification_form} phx-submit="submit_verification">
            <label class="block text-sm font-medium mb-2">Verification Code</label>
            <.input
              field={@verification_form[:code]}
              type="text"
              placeholder="Enter verification code"
              class="w-full bg-background border-input text-center text-2xl tracking-widest"
            />

            <%= if @code_valid? == false do %>
              <p class="mt-2 text-sm text-destructive">Invalid verification code</p>
            <% end %>

            <div class="flex justify-end">
              <.button type="submit">
                Next <.icon name="tabler-arrow-right" class="ml-2 size-4" />
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  defp main_content(%{step: :preferences} = assigns) do
    ~H"""
    <div class="space-y-6">
      <.form for={@preferences_form} phx-submit="submit_preferences" class="space-y-8">
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
                <.input
                  field={@preferences_form[:hourly_rate_min]}
                  icon="tabler-currency-dollar"
                  label="Min"
                  placeholder="0"
                  class="w-full bg-background border-input"
                  hide_errors
                />
              </div>
              <div class="flex-1">
                <.input
                  field={@preferences_form[:hourly_rate_max]}
                  icon="tabler-currency-dollar"
                  label="Max"
                  placeholder="0"
                  class="w-full bg-background border-input"
                  hide_errors
                />
              </div>
              <div class="flex-1">
                <.input
                  field={@preferences_form[:hours_per_week]}
                  icon="tabler-clock"
                  label="Hours per week"
                  placeholder="40"
                  class="w-full bg-background border-input"
                  hide_errors
                />
              </div>
            </div>
            <.error :for={
              msg <-
                [:hourly_rate_min, :hourly_rate_max, :hours_per_week]
                |> Enum.flat_map(&@preferences_form[&1].errors)
                |> Enum.map(&translate_error(&1))
            }>
              <%= msg %>
            </.error>
          </div>

          <div>
            <label class="block text-lg font-semibold mb-1">Are you hiring full-time?</label>
            <p class="text-muted-foreground mb-3 text-sm">
              We will match you with developers who are looking for full-time work
            </p>
            <div class="grid grid-cols-2 gap-4">
              <%= for {label, value} <- PreferencesForm.hiring_options() do %>
                <label class={[
                  "group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none",
                  "bg-background border-2 hover:border-primary hover:bg-primary/10 transition-all duration-200",
                  "border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10"
                ]}>
                  <div class="sr-only">
                    <.input
                      field={@preferences_form[:hiring]}
                      type="radio"
                      value={value}
                      checked={to_string(get_field(@preferences_form.source, :hiring)) == value}
                    />
                  </div>
                  <span class="flex flex-1 items-center justify-between">
                    <span class="text-sm font-medium"><%= label %></span>
                    <.icon
                      name="tabler-check"
                      class="size-5 text-primary invisible group-has-[:checked]:visible"
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
              <%= for {label, value} <- PreferencesForm.company_types_options() do %>
                <label class={[
                  "group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none",
                  "bg-background border-2 hover:border-primary hover:bg-primary/10 transition-all duration-200",
                  "border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10"
                ]}>
                  <div class="sr-only">
                    <.input
                      field={@preferences_form[:company_types]}
                      type="checkbox"
                      value={value}
                      checked={value in (get_field(@preferences_form.source, :company_types) || [])}
                      multiple
                    />
                  </div>
                  <span class="flex flex-1 items-center justify-between">
                    <span class="text-sm font-medium"><%= label %></span>
                    <.icon
                      name="tabler-check"
                      class="size-5 text-primary invisible group-has-[:checked]:visible"
                    />
                  </span>
                </label>
              <% end %>
            </div>
          </div>
        </div>

        <div class="flex justify-between">
          <.button type="button" phx-click="prev_step" variant="secondary">
            <.icon name="tabler-arrow-left" class="mr-2 size-4" /> Previous
          </.button>
          <.button type="submit">
            Meet developers <.icon name="tabler-users" class="ml-2 size-4" />
          </.button>
        </div>
      </.form>
    </div>
    """
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

            <.debug
              class="mb-4"
              data={%{tech_stack: get_field(@tech_stack_form.source, :tech_stack) || []}}
            />

            <div class="mb-4">
              <%= main_content(assigns) %>
            </div>
          </div>
        </div>
        <div class="w-1/3 border-l border-border bg-background px-6 py-4 overflow-y-auto h-screen">
          <%= sidebar_content(assigns) %>
          <!-- HACK: preload images to avoid layout shift -->
          <div class="fixed opacity-0">
            <%= sidebar_content(%{assigns | step: :email}) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp sidebar_content(%{step: :email} = assigns) do
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
end
