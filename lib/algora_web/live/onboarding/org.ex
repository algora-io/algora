defmodule AlgoraWeb.Onboarding.OrgLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import Ecto.Changeset

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Organizations
  alias AlgoraWeb.Components.Wordmarks
  alias AlgoraWeb.LocalStore
  alias Phoenix.LiveView.AsyncResult

  require Logger

  @steps [:tech_stack, :email, :preferences]

  # === SCHEMAS === #

  defmodule TechStackForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :tech_stack, {:array, :string}
    end

    def init do
      to_form(TechStackForm.changeset(%TechStackForm{}, %{tech_stack: []}))
    end

    def changeset(form, attrs) do
      cast(form, attrs, [:tech_stack])
    end
  end

  defmodule EmailForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :email, :string
      field :domain, :string
    end

    def init do
      to_form(EmailForm.changeset(%EmailForm{}, %{}))
    end

    def validate_domain_not_blacklisted(changeset) do
      domain = get_field(changeset, :domain)

      if not is_nil(domain) and Algora.Crawler.blacklisted?(domain) do
        add_error(changeset, :domain, "You can only use a company domain")
      else
        changeset
      end
    end

    def validate_email_is_company_domain(changeset) do
      domain = get_field(changeset, :domain)
      email = get_field(changeset, :email)

      if is_nil(email) or is_nil(domain) do
        changeset
      else
        case String.split(email, "@") do
          [_, ^domain] ->
            changeset

          [_, _not_email_domain] ->
            add_error(changeset, :email, "Your email address must match your company domain")
        end
      end
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:email, :domain])
      |> validate_required([:email, :domain])
      |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
      |> validate_format(:domain, ~r/^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$/,
        message: "must be a valid domain"
      )
      |> validate_domain_not_blacklisted()
    end
  end

  defmodule VerificationForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :code, :string
    end

    def init do
      to_form(VerificationForm.changeset(%VerificationForm{}, %{}))
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:code])
      |> validate_required([:code])
    end
  end

  defmodule PreferencesForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :hiring, :boolean
      field :categories, {:array, :string}
    end

    def hiring_options do
      [{"Yes", "true"}, {"No", "false"}]
    end

    def categories_options do
      [
        {"Open source company", "open_source"},
        {"Closed source company", "closed_source"},
        {"Agency / consultancy / studio", "agency"},
        {"Non-profit / FOSS", "nonprofit"}
      ]
    end

    def init do
      to_form(PreferencesForm.changeset(%PreferencesForm{}, %{categories: []}))
    end

    def changeset(form, attrs) do
      cast(form, attrs, [:hiring, :categories])
    end
  end

  # === LIFECYCLE === #

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:ip_address, AlgoraWeb.Util.get_ip(socket))
     |> assign(:tech_stack_form, TechStackForm.init())
     |> assign(:email_form, EmailForm.init())
     |> assign(:verification_form, VerificationForm.init())
     |> assign(:preferences_form, PreferencesForm.init())
     |> assign(:step, Enum.at(@steps, 0))
     |> assign(:steps, @steps)
     |> assign(:code_sent?, false)
     |> assign(:code_valid?, nil)
     |> assign(:timezone, nil)
     |> assign(:secret, nil)
     |> assign(:user_metadata, AsyncResult.loading())
     |> assign_matching_devs()}
  end

  # === EVENT HANDLERS === #

  def handle_params(params, _uri, socket) do
    socket =
      LocalStore.init(socket,
        key: __MODULE__,
        checkpoint_url: ~p"/onboarding/org?#{%{checkpoint: "1"}}"
      )

    socket = if params["checkpoint"] == "1", do: LocalStore.subscribe(socket), else: socket

    {:noreply, socket}
  end

  def handle_event("restore_settings", params, socket) do
    {:noreply, LocalStore.restore(socket, params)}
  end

  def handle_event("prev_step", _, socket) do
    current_step_index = Enum.find_index(socket.assigns.steps, &(&1 == socket.assigns.step))
    prev_step = Enum.at(socket.assigns.steps, current_step_index - 1)
    {:noreply, assign(socket, :step, prev_step)}
  end

  def handle_event("submit_tech_stack", %{"tech_stack_form" => params}, socket) do
    tech_stack =
      Jason.decode!(params["tech_stack"]) ++
        case String.trim(params["tech_stack_input"]) do
          "" -> []
          tech_stack_input -> String.split(tech_stack_input, ",")
        end

    changeset =
      %TechStackForm{}
      |> TechStackForm.changeset(%{tech_stack: tech_stack})
      |> Map.put(:action, :validate)

    case changeset do
      %{valid?: true} ->
        {:noreply,
         socket
         |> LocalStore.assign_cached(:tech_stack_form, to_form(changeset))
         |> LocalStore.assign_cached(:step, :email)
         |> assign_matching_devs()}

      %{valid?: false} ->
        {:noreply, LocalStore.assign_cached(socket, :tech_stack_form, to_form(changeset))}
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
        {secret, code} = AlgoraWeb.UserAuth.generate_totp()

        {:ok, _} = Accounts.deliver_totp_signup_email(email, code)

        {:noreply,
         socket
         |> LocalStore.assign_cached(:secret, secret)
         |> LocalStore.assign_cached(:email_form, to_form(changeset))
         |> LocalStore.assign_cached(:code_sent?, true)
         |> assign_matching_devs()
         |> start_async(:fetch_metadata, fn -> Algora.Crawler.fetch_user_metadata(email) end)
         |> assign(:user_metadata, AsyncResult.loading())}

      %{valid?: false} = changeset ->
        {:noreply, LocalStore.assign_cached(socket, :email_form, to_form(changeset))}
    end
  end

  def handle_event("submit_preferences", params, socket) do
    changeset =
      %PreferencesForm{}
      |> PreferencesForm.changeset(params["preferences_form"] || %{})
      |> Map.put(:action, :validate)

    case changeset do
      %{valid?: true} ->
        # Get all the form data
        email = get_field(socket.assigns.email_form.source, :email)
        domain = get_field(socket.assigns.email_form.source, :domain)
        tech_stack = get_field(socket.assigns.tech_stack_form.source, :tech_stack)
        preferences = changeset.changes

        if socket.assigns.code_valid? do
          metadata =
            case socket.assigns.user_metadata do
              %AsyncResult{ok?: true, result: metadata} -> metadata
              _ -> %{}
            end

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

          user_handle = Organizations.generate_handle_from_email(email)

          org_params =
            %{
              display_name: org_name,
              bio:
                get_in(metadata, [:org, :bio]) ||
                  get_in(metadata, [:org, :og_description]) ||
                  get_in(metadata, [:org, :og_title]),
              avatar_url: get_in(metadata, [:org, :avatar_url]) || get_in(metadata, [:org, :favicon_url]),
              handle: org_handle,
              domain: domain,
              og_title: get_in(metadata, [:org, :og_title]),
              og_image_url: get_in(metadata, [:org, :og_image_url]),
              tech_stack: tech_stack,
              hiring: get_in(preferences, [:hiring]),
              categories: get_in(preferences, [:categories]),
              website_url: get_in(metadata, [:org, :website_url]),
              twitter_url: get_in(metadata, [:org, :socials, :twitter]),
              github_url: get_in(metadata, [:org, :socials, :github]),
              youtube_url: get_in(metadata, [:org, :socials, :youtube]),
              twitch_url: get_in(metadata, [:org, :socials, :twitch]),
              discord_url: get_in(metadata, [:org, :socials, :discord]),
              slack_url: get_in(metadata, [:org, :socials, :slack]),
              linkedin_url: get_in(metadata, [:org, :socials, :linkedin])
            }

          user_params =
            %{
              email: email,
              display_name: user_handle,
              avatar_url: get_in(metadata, [:avatar_url]),
              handle: user_handle,
              tech_stack: tech_stack,
              timezone: socket.assigns.timezone
            }

          member_params =
            %{
              role: :admin
            }

          params =
            %{
              organization: org_params,
              user: user_params,
              member: member_params
            }

          socket =
            case Algora.Organizations.onboard_organization(params) do
              {:ok, _} ->
                redirect(socket, to: AlgoraWeb.UserAuth.generate_login_path(email))

              {:error, name, changeset, _created} ->
                Logger.error("error onboarding organization: #{inspect(name)} #{inspect(changeset)}")

                socket
                |> put_flash(:error, "Something went wrong. Please try again.")
                |> redirect(to: "/")
            end

          {:noreply, socket}
        else
          throttle()

          {:noreply,
           socket
           |> put_flash(:error, "Invalid verification code")
           |> LocalStore.assign_cached(:step, :email)}
        end

      %{valid?: false} ->
        {:noreply, LocalStore.assign_cached(socket, :preferences_form, to_form(changeset))}
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

        case AlgoraWeb.UserAuth.verify_totp(socket.assigns.ip_address, socket.assigns.secret, String.trim(code)) do
          :ok ->
            {:noreply,
             socket
             |> LocalStore.assign_cached(:verification_form, to_form(changeset))
             |> LocalStore.assign_cached(:code_valid?, true)
             |> LocalStore.assign_cached(:step, :preferences)}

          {:error, :rate_limit_exceeded} ->
            throttle()
            {:noreply, put_flash(socket, :error, "Too many attempts. Please try again later.")}

          {:error, :invalid_totp} ->
            throttle()
            {:noreply, put_flash(socket, :error, "Invalid verification code")}
        end

      %{valid?: false} = changeset ->
        {:noreply, LocalStore.assign_cached(socket, :verification_form, to_form(changeset))}
    end
  end

  def handle_event("tech_stack_changed", %{"tech_stack" => tech_stack}, socket) do
    changeset = TechStackForm.changeset(%TechStackForm{}, %{tech_stack: tech_stack})

    {:noreply,
     socket
     |> LocalStore.assign_cached(:tech_stack_form, to_form(changeset))
     |> assign_matching_devs()}
  end

  def handle_event("timezone_changed", %{"timezone" => timezone}, socket) do
    {:noreply, assign(socket, :timezone, timezone)}
  end

  # === PRIVATE HELPERS === #

  defp assign_matching_devs(socket) do
    tech_stack = get_field(socket.assigns.tech_stack_form.source, :tech_stack)

    matching_devs =
      Accounts.list_developers(
        limit: 5,
        sort_by_tech_stack: tech_stack,
        sort_by_country: socket.assigns.current_country,
        earnings_gt: Money.new!(200, "USD")
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
          <h2 class="mb-3 text-3xl sm:text-4xl font-semibold">
            What's your tech stack?
          </h2>
          <p class="text-muted-foreground">
            Enter a comma-separated list
          </p>

          <.TechStack
            classes="mt-4 border-2 border-foreground/50"
            tech={get_field(@tech_stack_form.source, :tech_stack) || []}
            socket={@socket}
            form="tech_stack_form"
          />

          <.error :for={msg <- @tech_stack_form[:tech_stack].errors |> Enum.map(&translate_error(&1))}>
            {msg}
          </.error>
        </div>

        <div class="flex justify-end gap-4">
          <.button type="submit" variant="secondary">
            Skip
          </.button>
          <.button type="submit">
            Next
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  defp main_content(%{step: :email, code_sent?: false} = assigns) do
    ~H"""
    <div class="space-y-4">
      <h2 class="mb-3 text-3xl sm:text-4xl font-semibold">
        Join with your team
      </h2>

      <.form for={@email_form} phx-submit="submit_email" class="space-y-6">
        <.input
          field={@email_form[:email]}
          label="Work Email"
          icon="tabler-mail"
          type="text"
          placeholder="you@company.com"
          class="w-full border-input bg-background"
          data-domain-target
          phx-hook="DeriveDomain"
          autocomplete="email"
        />
        <.input
          field={@email_form[:domain]}
          icon="tabler-at"
          label="Company Domain"
          helptext="This will let your teammates auto-join your org"
          type="text"
          placeholder="company.com"
          class="w-full border-input bg-background"
          data-domain-source
        />
        <p class="mt-4 text-sm text-muted-foreground/75">
          By continuing, you agree to Algora's
          <.link href={AlgoraWeb.Constants.get(:terms_url)} class="text-primary hover:underline">
            Terms of Service
          </.link>
          and <.link href={AlgoraWeb.Constants.get(:privacy_url)} class="text-primary hover:underline">Privacy Policy</.link>.
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
        <h2 class="mb-3 text-3xl sm:text-4xl font-semibold">
          Verify your email
        </h2>
        <p class="text-muted-foreground">
          We've sent a code to {get_field(@email_form.source, :email)}
        </p>

        <div class="mt-6">
          <.form for={@verification_form} phx-submit="submit_verification" class="space-y-6">
            <label class="mb-2 block text-sm font-medium">Verification Code</label>
            <.input
              field={@verification_form[:code]}
              type="text"
              placeholder="Enter verification code"
              class="w-full border-input bg-background text-center text-xl sm:text-2xl tracking-widest"
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
          <h2 class="text-3xl sm:text-4xl font-semibold">
            Let's personalize your experience
          </h2>
          <p class="mt-2 text-muted-foreground">
            We'll use this information to match you with the best developers
          </p>
        </div>

        <div class="space-y-8">
          <div>
            <label class="mb-1 block text-lg font-semibold">Are you hiring full-time?</label>
            <p class="mb-3 text-sm text-muted-foreground">
              We will match you with developers who are looking for full-time work
            </p>
            <div class="grid grid-cols-2 gap-4">
              <%= for {label, value} <- PreferencesForm.hiring_options() do %>
                <label class={[
                  "group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none",
                  "border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10",
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
                    <span class="text-sm font-medium">{label}</span>
                    <.icon
                      name="tabler-check"
                      class="invisible size-5 text-primary group-has-[:checked]:visible"
                    />
                  </span>
                </label>
              <% end %>
            </div>
            <.error :for={msg <- @preferences_form[:hiring].errors |> Enum.map(&translate_error(&1))}>
              {msg}
            </.error>
          </div>

          <div>
            <label class="mb-1 block text-lg font-semibold">
              Which of the following best describes you?
            </label>
            <p class="mb-3 text-sm text-muted-foreground">
              Select all that apply
            </p>
            <div class="grid grid-cols-2 gap-4">
              <%= for {label, value} <- PreferencesForm.categories_options() do %>
                <label class={[
                  "group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none",
                  "border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10",
                  "border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10"
                ]}>
                  <div class="sr-only">
                    <.input
                      field={@preferences_form[:categories]}
                      type="checkbox"
                      value={value}
                      checked={value in (get_field(@preferences_form.source, :categories) || [])}
                      multiple
                    />
                  </div>
                  <span class="flex flex-1 items-center justify-between">
                    <span class="text-sm font-medium">{label}</span>
                    <.icon
                      name="tabler-check"
                      class="invisible size-5 text-primary group-has-[:checked]:visible"
                    />
                  </span>
                </label>
              <% end %>
            </div>
            <.error :for={
              msg <- @preferences_form[:categories].errors |> Enum.map(&translate_error(&1))
            }>
              {msg}
            </.error>
          </div>
        </div>

        <div class="flex justify-end gap-4">
          <.button type="submit" variant="secondary">
            Skip
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
    <div class="min-h-screen bg-card" phx-hook="LocalStateStore" id="onboarding-page">
      <div class="flex flex-col lg:flex-row flex-1">
        <div class="flex-grow px-8 py-16">
          <div class="mx-auto max-w-3xl">
            <div class="mb-4">
              {main_content(assigns)}
            </div>
          </div>
        </div>
        <div class="w-full px-6 py-4 lg:w-1/3 lg:h-screen lg:overflow-y-auto lg:border-l lg:border-border lg:bg-background">
          {sidebar_content(assigns)}
          <!-- HACK: preload images to avoid layout shift -->
          <div class="fixed opacity-0">
            {sidebar_content(%{assigns | step: :email})}
          </div>
        </div>
      </div>
    </div>
    <.Timezone socket={@socket} />
    """
  end

  defp sidebar_content(%{step: :email} = assigns) do
    ~H"""
    <div>
      <h2 class="mb-6 text-lg font-semibold uppercase">
        You're in good company
      </h2>
      <div class="grid w-full grid-cols-2 items-center justify-center gap-x-10 gap-y-16">
        <a class="relative flex items-center justify-center" href={~p"/cal"}>
          <Wordmarks.calcom class="w-[10rem] col-auto mt-3" alt="Cal.com" />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/qdrant"}>
          <Wordmarks.qdrant class="w-[11rem] col-auto" alt="Qdrant" />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/remotion"}>
          <img
            src={~p"/images/wordmarks/remotion.png"}
            alt="Remotion"
            class="col-auto w-full saturate-0"
          />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/zio"}>
          <img
            src={~p"/images/wordmarks/zio.png"}
            alt="ZIO"
            class="w-[10rem] col-auto brightness-0 invert"
          />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/triggerdotdev"}>
          <img
            src={~p"/images/wordmarks/triggerdotdev.png"}
            alt="Trigger.dev"
            class="col-auto w-full saturate-0"
          />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/tembo"}>
          <img
            src={~p"/images/wordmarks/tembo.png"}
            alt="Tembo"
            class="w-[13rem] col-auto saturate-0"
          />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/maybe-finance"}>
          <img src={~p"/images/wordmarks/maybe.png"} alt="Maybe" class="col-auto w-full saturate-0" />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/golemcloud"}>
          <Wordmarks.golemcloud class="col-auto w-full" alt="Golem Cloud" />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/aidenybai"}>
          <img src={~p"/images/wordmarks/million.png"} alt="Million" class="col-auto w-44 saturate-0" />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/tailcallhq"}>
          <Wordmarks.tailcall class="w-[10rem] col-auto" fill="white" alt="Tailcall" />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/highlight"}>
          <img
            src={~p"/images/wordmarks/highlight.png"}
            alt="Highlight"
            class="col-auto w-44 saturate-0"
          />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/dittofeed"}>
          <img
            src={~p"/images/wordmarks/dittofeed.png"}
            alt="Dittofeed"
            class="col-auto w-40 brightness-0 invert"
          />
        </a>
      </div>
    </div>
    """
  end

  defp sidebar_content(assigns) do
    ~H"""
    <div>
      <h2 class="mb-4 text-lg font-semibold uppercase">
        Matching Developers
      </h2>
      <%= for dev <- @matching_devs do %>
        <div class="mb-6 rounded-lg border border-border bg-card p-4">
          <div class="mb-2 flex gap-3">
            <img src={dev.avatar_url} alt={dev.name} class="h-24 w-24 rounded-full" />
            <div class="flex-grow">
              <div class="flex justify-between">
                <div>
                  <div class="font-semibold">
                    {dev.name} {Algora.Misc.CountryEmojis.get(dev.country)}
                  </div>
                  <div class="text-sm text-muted-foreground">@{User.handle(dev)}</div>
                </div>
                <div class="flex flex-col items-end">
                  <div class="text-muted-foreground">Earned</div>
                  <div class="font-display font-semibold text-success">
                    {Money.to_string!(dev.total_earned)}
                  </div>
                </div>
              </div>

              <div class="pt-3 text-sm">
                <div class="-ml-1 flex flex-wrap gap-3 text-sm">
                  <%= for tech <- dev.tech_stack do %>
                    <span class="rounded-lg bg-secondary px-2 py-0.5 text-sm ring-1 ring-border">
                      {tech}
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

  def handle_async(:fetch_metadata, {:ok, metadata}, socket) do
    {:noreply, LocalStore.assign_cached(socket, :user_metadata, AsyncResult.ok(socket.assigns.user_metadata, metadata))}
  end

  def handle_async(:fetch_metadata, {:exit, reason}, socket) do
    {:noreply, assign(socket, :user_metadata, AsyncResult.failed(socket.assigns.user_metadata, reason))}
  end

  defp throttle, do: :timer.sleep(1000)
end
