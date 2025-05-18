defmodule AlgoraWeb.Onboarding.DevLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Github
  alias Algora.Organizations
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.LocalStore

  require Logger

  @steps [:info, :oauth]

  defmodule InfoForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :tech_stack, {:array, :string}
      field :intentions, {:array, :string}
    end

    def init do
      to_form(InfoForm.changeset(%InfoForm{}, %{tech_stack: [], intentions: []}))
    end

    def changeset(form, attrs) do
      cast(form, attrs, [:tech_stack, :intentions])
    end

    def intentions_options do
      [
        {"bounties", "Solve Bounties", "Work on open source issues & earn rewards", "tabler-diamond"},
        {"jobs", "Find Full-time Work", "Get matched with companies hiring devs", "tabler-briefcase"},
        {"contracts", "Freelance Work", "Take on flexible contract-based projects", "tabler-clock"}
      ]
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    context = %{
      country: socket.assigns.current_country,
      tech_stack: [],
      intentions: []
    }

    transactions =
      Repo.all(
        from tx in Transaction,
          where: tx.type == :credit,
          where: not is_nil(tx.succeeded_at),
          where:
            fragment(
              "? >= ('USD', 500)::money_with_currency",
              tx.net_amount
            ),
          join: u in assoc(tx, :user),
          join: b in assoc(tx, :bounty),
          join: t in assoc(b, :ticket),
          join: r in assoc(t, :repository),
          join: o in assoc(r, :user),
          select_merge: %{user: u, bounty: %{b | ticket: %{t | repository: %{r | user: o}}}},
          order_by: [desc: tx.succeeded_at],
          limit: 10
      )

    signup_form = to_form(User.signup_changeset(%User{}, %{}))

    {:ok,
     socket
     |> assign(:ip_address, AlgoraWeb.Util.get_ip(socket))
     |> assign(:secret, nil)
     |> assign(:step, Enum.at(@steps, 0))
     |> assign(:steps, @steps)
     |> assign(:total_steps, length(@steps))
     |> assign(:context, context)
     |> assign(:transactions, transactions)
     |> assign(:info_form, InfoForm.init())
     |> assign(:signup_form, signup_form)}
  end

  @impl true
  def render(%{current_user: current_user} = assigns) when not is_nil(current_user) do
    ~H"""
    <div
      class="w-screen h-screen fixed inset-0 bg-background z-[100]"
      phx-hook="LocalStateStore"
      id="onboarding-dev-page"
    >
      <div class="flex items-center justify-center h-full">
        <svg
          class="mr-3 -ml-1 size-12 animate-spin text-success"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
          </circle>
          <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          >
          </path>
        </svg>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-card" phx-hook="LocalStateStore" id="onboarding-dev-page">
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
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      LocalStore.init(socket,
        key: __MODULE__,
        checkpoint_url: ~p"/onboarding/dev?#{%{checkpoint: "1"}}"
      )

    socket = if params["checkpoint"] == "1", do: LocalStore.subscribe(socket), else: socket

    {:noreply, socket}
  end

  @impl true
  def handle_event("restore_settings", params, socket) do
    socket = LocalStore.restore(socket, params)

    if user = socket.assigns[:current_user] do
      tech_stack = get_field(socket.assigns.info_form.source, :tech_stack) || []
      intentions = get_field(socket.assigns.info_form.source, :intentions) || []

      case user
           |> change(
             tech_stack: tech_stack,
             seeking_bounties: "bounties" in intentions,
             seeking_contracts: "contracts" in intentions,
             seeking_jobs: "jobs" in intentions
           )
           |> Repo.update() do
        {:ok, user} ->
          {:noreply, redirect(socket, to: AlgoraWeb.UserAuth.generate_login_path(user.email))}

        {:error, changeset} ->
          Logger.error("Failed to update user #{user.id} on onboarding: #{inspect(changeset)}")
          {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("sign_in_with_github", _params, socket) do
    {:noreply, redirect(socket, external: Github.authorize_url(%{return_to: ~p"/onboarding/dev?checkpoint=1"}))}
  end

  @impl true
  def handle_event("send_signup_code", %{"user" => %{"email" => email}}, socket) do
    {secret, code} = AlgoraWeb.UserAuth.generate_totp()

    changeset = User.signup_changeset(%User{}, %{})

    case Algora.Accounts.deliver_totp_signup_email(email, code) do
      {:ok, _id} ->
        {:noreply,
         socket
         |> LocalStore.assign_cached(:secret, secret)
         |> LocalStore.assign_cached(:email, email)
         |> assign(:signup_form, to_form(changeset))}

      {:error, reason} ->
        Logger.error("Failed to send signup code to #{email}: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "We had trouble sending mail to #{email}. Please try again")}
    end
  end

  @impl true
  def handle_event("send_signup_code", %{"user" => %{"signup_code" => code}}, socket) do
    case AlgoraWeb.UserAuth.verify_totp(socket.assigns.ip_address, socket.assigns.secret, String.trim(code)) do
      :ok ->
        user_handle =
          socket.assigns.email
          |> String.replace(~r/[^a-zA-Z0-9]/, "-")
          |> String.downcase()

        email = socket.assigns.email

        tech_stack = get_field(socket.assigns.info_form.source, :tech_stack) || []
        intentions = get_field(socket.assigns.info_form.source, :intentions) || []

        opts = [
          tech_stack: tech_stack,
          seeking_bounties: "bounties" in intentions,
          seeking_contracts: "contracts" in intentions,
          seeking_jobs: "jobs" in intentions
        ]

        {:ok, user} =
          case Repo.get_by(User, email: email) do
            nil ->
              %User{
                type: :individual,
                last_context: "personal",
                handle: Organizations.ensure_unique_handle(user_handle),
                avatar_url: Algora.Util.get_gravatar_url(email)
              }
              |> User.signup_changeset(%{email: email})
              |> User.generate_id()
              |> change(opts)
              |> Repo.insert()

            existing_user ->
              existing_user
              |> change(opts)
              |> Repo.update()
          end

        {:noreply, redirect(socket, to: AlgoraWeb.UserAuth.generate_login_path(user.email, socket.assigns[:return_to]))}

      {:error, :rate_limit_exceeded} ->
        throttle()
        {:noreply, put_flash(socket, :error, "Too many attempts. Please try again later.")}

      {:error, :invalid_totp} ->
        throttle()
        {:noreply, put_flash(socket, :error, "Invalid signup code")}
    end
  end

  @impl true
  def handle_event("prev_step", _params, socket) do
    current_step_index = Enum.find_index(socket.assigns.steps, &(&1 == socket.assigns.step))
    prev_step = Enum.at(socket.assigns.steps, current_step_index - 1)
    {:noreply, assign(socket, :step, prev_step)}
  end

  @impl true
  def handle_event("tech_stack_changed", %{"tech_stack" => tech_stack}, socket) do
    changeset = InfoForm.changeset(socket.assigns.info_form.source, %{tech_stack: tech_stack})
    {:noreply, LocalStore.assign_cached(socket, :info_form, to_form(changeset))}
  end

  def handle_event("validate_info", %{"info_form" => params}, socket) do
    changeset = InfoForm.changeset(socket.assigns.info_form.source, params)
    {:noreply, LocalStore.assign_cached(socket, :info_form, to_form(changeset))}
  end

  @impl true
  def handle_event("submit_info", %{"info_form" => params}, socket) do
    tech_stack =
      Jason.decode!(params["tech_stack"]) ++
        case String.trim(params["tech_stack_input"]) do
          "" -> []
          tech_stack_input -> String.split(tech_stack_input, ",")
        end

    changeset =
      %InfoForm{}
      |> InfoForm.changeset(%{tech_stack: tech_stack, intentions: params["intentions"]})
      |> Map.put(:action, :validate)

    case changeset do
      %{valid?: true} ->
        {:noreply,
         socket
         |> LocalStore.assign_cached(:info_form, to_form(changeset))
         |> LocalStore.assign_cached(:step, :oauth)}

      %{valid?: false} ->
        {:noreply, LocalStore.assign_cached(socket, :info_form, to_form(changeset))}
    end
  end

  defp throttle, do: :timer.sleep(1000)

  defp main_content(%{step: :info} = assigns) do
    ~H"""
    <div class="space-y-8">
      <.form for={@info_form} phx-change="validate_info" phx-submit="submit_info" class="space-y-8">
        <div>
          <h2 class="mb-2 text-3xl sm:text-4xl font-semibold">
            What's your tech stack?
          </h2>
          <p class="text-muted-foreground">Enter a comma-separated list</p>

          <.TechStack
            classes="mt-4 border-2 border-foreground/50"
            tech={get_field(@info_form.source, :tech_stack) || []}
            socket={@socket}
            form="info_form"
          />

          <.error :for={msg <- @info_form[:tech_stack].errors |> Enum.map(&translate_error(&1))}>
            {msg}
          </.error>
        </div>

        <div class="mt-8">
          <h2 class="mb-2 text-3xl sm:text-4xl font-semibold">
            What are your goals?
          </h2>
          <p class="text-muted-foreground">Select all that apply</p>

          <div class="mt-2 -ml-4">
            <%= for {value, label, description, icon} <- InfoForm.intentions_options() do %>
              <label class="flex cursor-pointer items-center gap-3 rounded-lg p-4 hover:bg-muted/50">
                <.input
                  field={@info_form[:intentions]}
                  type="checkbox"
                  value={value}
                  checked={value in (get_field(@info_form.source, :intentions) || [])}
                  class="cursor-pointer h-10 w-10 rounded border-2 border-foreground/50 bg-background text-primary focus:ring-primary focus:ring-offset-background"
                  multiple
                />
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <.icon name={icon} class="h-5 w-5 text-muted-foreground" />
                    <span class="font-medium">{label}</span>
                  </div>
                  <p class="mt-0.5 text-sm text-muted-foreground">
                    {description}
                  </p>
                </div>
              </label>
            <% end %>
          </div>

          <.error :for={msg <- @info_form[:intentions].errors |> Enum.map(&translate_error(&1))}>
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

  defp main_content(%{step: :oauth} = assigns) do
    ~H"""
    <div class="max-w-sm">
      <h2 class="mb-2 text-3xl sm:text-4xl font-semibold">
        Complete your signup
      </h2>
      <p class="mb-6 text-muted-foreground">
        Join our community and start earning bounties
      </p>

      <div class="mt-8">
        <.button :if={!@secret} phx-click="sign_in_with_github" class="w-full py-5">
          <Logos.github class="size-5 mr-2 -ml-1 shrink-0" /> Continue with GitHub
        </.button>

        <div :if={!@secret} class="relative mt-6">
          <div class="absolute inset-0 flex items-center" aria-hidden="true">
            <div class="w-full border-t border-muted-foreground/50"></div>
          </div>
          <div class="relative flex justify-center text-sm/6 font-medium">
            <span class="bg-background px-6 text-muted-foreground">or</span>
          </div>
        </div>

        <div class="mt-4">
          <.simple_form
            :if={!@secret}
            for={@signup_form}
            id="send_signup_code_form"
            phx-submit="send_signup_code"
          >
            <div class="space-y-4">
              <.input
                field={@signup_form[:email]}
                type="email"
                label="Email"
                placeholder="you@example.com"
                required
              />
              <.button phx-disable-with="Signing up..." class="w-full py-5" variant="secondary">
                Continue with email
              </.button>
            </div>
          </.simple_form>
        </div>

        <.simple_form
          :if={@secret}
          for={@signup_form}
          id="send_signup_code_form"
          phx-submit="send_signup_code"
        >
          <.input field={@signup_form[:signup_code]} type="text" label="Signup code" required />
          <.button phx-disable-with="Signing up..." class="w-full py-5">
            Submit
          </.button>
        </.simple_form>
      </div>

      <div class="mt-4 text-xs sm:text-sm text-muted-foreground w-full">
        By continuing, you agree to our
        <.link
          href={AlgoraWeb.Constants.get(:terms_url)}
          class="font-medium text-foreground/90 hover:text-foreground"
        >
          terms
        </.link>
        {" "} and
        <.link
          href={AlgoraWeb.Constants.get(:privacy_url)}
          class="font-medium text-foreground/90 hover:text-foreground"
        >
          privacy policy.
        </.link>
      </div>
    </div>
    """
  end

  defp sidebar_content(assigns) do
    ~H"""
    <h2 class="mb-4 text-lg font-semibold uppercase">
      Recently Completed Bounties
    </h2>
    <%= if @transactions == [] do %>
      <p class="text-muted-foreground">No completed bounties available</p>
    <% else %>
      <%= for transaction <- @transactions do %>
        <div class="mb-4 rounded-lg border border-border bg-card p-4">
          <div class="flex gap-4">
            <div class="flex-1">
              <div class="mb-2 font-mono text-2xl font-extrabold text-success">
                {Money.to_string!(transaction.net_amount)}
              </div>
              <div class="mb-1 text-sm text-muted-foreground">
                {transaction.bounty.ticket.repository.user.provider_login}/{transaction.bounty.ticket.repository.name}#{transaction.bounty.ticket.number}
              </div>
              <div class="font-medium break-all">
                {transaction.bounty.ticket.title}
              </div>
              <div class="mt-1 text-xs text-muted-foreground">
                {Algora.Util.time_ago(transaction.succeeded_at)}
              </div>
            </div>

            <div class="flex w-32 flex-col items-center border-l border-border pl-4">
              <h3 class="mb-3 text-xs font-medium uppercase text-muted-foreground">
                Awarded to
              </h3>
              <img
                src={transaction.user.avatar_url}
                class="mb-2 h-16 w-16 rounded-full"
                alt={transaction.user.name}
              />
              <div class="text-center text-sm font-medium">
                {transaction.user.name}
                <div>
                  {Algora.Misc.CountryEmojis.get(transaction.user.country)}
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    <% end %>
    """
  end
end
