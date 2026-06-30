defmodule AlgoraWeb.SignInLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Organizations
  alias Algora.Repo
  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.LocalStore

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-[100svh] bg-[#111113]" id="sign-in-page" phx-hook="LocalStateStore">
      <div class="relative flex flex-1 flex-col justify-center px-4 py-16 sm:px-6 lg:flex-none lg:px-20 xl:px-24 lg:border-r lg:border-border">
        <.wordmark class="h-10 w-auto absolute top-4 left-4 sm:top-8 sm:left-8" />
        <div class="mx-auto w-full max-w-sm lg:w-96 h-auto flex flex-col min-h-[426px]">
          <div :if={!@secret}>
            <h2 class="mt-8 text-3xl/9 font-bold tracking-tight text-foreground">
              <%= if @mode == :signup do %>
                Create an account
              <% else %>
                Welcome back
              <% end %>
            </h2>
            <p class="mt-2 text-base/6 text-muted-foreground">
              <%= if @mode == :signup do %>
                Sign up to get started
              <% else %>
                Sign in to your account
              <% end %>
            </p>

            <div :if={@mode == :signup} class="mt-6">
              <label class="mb-2 block text-sm/6 font-semibold">Sign up as...</label>
              <div class="grid grid-cols-2 gap-4">
                <.button navigate={~p"/onboarding/org"}>
                  Company
                </.button>
                <.button navigate={~p"/onboarding/dev"}>
                  Developer
                </.button>
              </div>
            </div>
            <div :if={@mode == :login} class="mt-6">
              <label class="mb-2 block text-sm/6 font-semibold">Sign in as...</label>
              <div class="grid grid-cols-2 gap-4">
                <label class={[
                  "group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none",
                  "border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10",
                  "border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10"
                ]}>
                  <input
                    type="radio"
                    name="user_type"
                    value="company"
                    checked={@user_type == "company"}
                    class="sr-only"
                    phx-click={JS.show(to: "#company-form") |> JS.hide(to: "#developer-form")}
                  />
                  <span class="flex flex-1 items-center justify-between">
                    <span class="text-sm font-medium">Company</span>
                    <.icon
                      name="tabler-check"
                      class="invisible size-5 text-primary group-has-[:checked]:visible"
                    />
                  </span>
                </label>
                <label class={[
                  "group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none",
                  "border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10",
                  "border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10"
                ]}>
                  <input
                    type="radio"
                    name="user_type"
                    value="developer"
                    checked={@user_type == "developer"}
                    class="sr-only"
                    phx-click={JS.show(to: "#developer-form") |> JS.hide(to: "#company-form")}
                  />
                  <span class="flex flex-1 items-center justify-between">
                    <span class="text-sm font-medium">Developer</span>
                    <.icon
                      name="tabler-check"
                      class="invisible size-5 text-primary group-has-[:checked]:visible"
                    />
                  </span>
                </label>
              </div>
            </div>
          </div>

          <div :if={@secret}>
            <h2 class="mt-8 text-3xl/9 font-bold tracking-tight text-foreground">
              Check your email
            </h2>
            <p class="mt-2 text-base/6 text-muted-foreground">
              Enter the login code we sent you
            </p>
          </div>

          <div :if={@mode == :login} class="mt-8">
            <div id="company-form" class={if @user_type == "developer", do: "hidden"}>
              <.simple_form
                :if={!@secret}
                for={@form}
                id="send_login_code_form"
                phx-submit="send_login_code"
              >
                <.input
                  field={@form[:email]}
                  type="email"
                  label="Email"
                  placeholder="you@example.com"
                  required
                />
                <.button phx-disable-with="Signing in..." class="w-full py-5">
                  Sign in
                </.button>
              </.simple_form>
            </div>

            <div id="developer-form" class={if @user_type == "company", do: "hidden"}>
              <.button :if={!@secret} href={@authorize_url} class="w-full py-5">
                <Logos.github class="size-5 mr-2 -ml-1 shrink-0" /> Continue with GitHub
              </.button>
            </div>

            <.simple_form
              :if={@secret}
              for={@form}
              id="send_login_code_form"
              phx-submit="send_login_code"
            >
              <.input field={@form[:login_code]} type="text" label="Login code" required />
              <.button phx-disable-with="Signing in..." class="w-full py-5">
                Submit
              </.button>
            </.simple_form>
          </div>

          <div :if={!@secret} class="mt-8 text-center text-sm text-muted-foreground">
            <%= if @mode == :signup do %>
              Already have an account?
              <.link
                navigate={~p"/auth/login"}
                class="underline font-medium text-foreground/90 hover:text-foreground"
              >
                Sign in now
              </.link>
            <% else %>
              Don't have an account?
              <.link
                navigate={~p"/auth/signup"}
                class="underline font-medium text-foreground/90 hover:text-foreground"
              >
                Sign up now
              </.link>
            <% end %>
          </div>

          <div class="absolute bottom-8 text-center text-xs sm:text-sm text-muted-foreground max-w-[calc(100vw-2rem)] sm:max-w-sm w-full mx-auto">
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
      </div>
      <div class="relative hidden w-0 flex-1 lg:block">
        <div class="absolute inset-0 overflow-y-auto bg-background">
          <div class="w-full mt-12 max-w-3xl mx-auto flex flex-col text-left px-12 pb-16">
            <h3 class="text-xl sm:text-2xl font-semibold tracking-tight text-foreground text-center">
              How it works
            </h3>
            <div class="space-y-12 mt-4">
              <div class="w-full space-y-4">
                <div class="flex items-start gap-2 sm:gap-3">
                  <.icon name="tabler-circle-number-1" class="w-6 h-6 text-foreground shrink-0" />
                  <p class="text-foreground text-sm sm:text-base font-medium">
                    Share your JDs and receive handpicked candidates with the right skills and experience
                  </p>
                </div>
                <div class="relative z-30 mx-auto">
                  <div class="group/card h-full border-2 border-white/10 bg-muted group relative flex-1 overflow-hidden rounded-xl">
                    <div class="grid h-7 grid-cols-[1fr_auto_1fr] overflow-hidden border-b border-gray-800">
                      <div class="ml-2 flex items-center gap-1">
                        <div class="h-2.5 w-2.5 rounded-full bg-red-400"></div>
                        <div class="h-2.5 w-2.5 rounded-full bg-yellow-400"></div>
                        <div class="h-2.5 w-2.5 rounded-full bg-green-400"></div>
                      </div>
                      <div class="flex items-center justify-center gap-2">
                        <img src={~p"/images/logo-192px.png"} alt="Algora" class="w-4 h-4 rounded" />
                        <div class="text-xs text-foreground">
                          algora.io<span class="text-foreground/70">/candidates</span>
                        </div>
                      </div>
                      <div></div>
                    </div>
                    <div class="relative flex aspect-[1200/630] h-full w-full items-center justify-center">
                      <img
                        src={~p"/images/screenshots/candidates-page.png"}
                        alt="Candidates page"
                        class="w-full bg-[#121214] p-1"
                      />
                    </div>
                  </div>
                </div>
              </div>
              <div class="w-full space-y-4">
                <div class="flex items-start gap-2 sm:gap-3">
                  <.icon name="tabler-circle-number-2" class="w-6 h-6 text-foreground shrink-0" />
                  <p class="text-foreground text-sm sm:text-base font-medium">
                    Get notified in your inbox and Slack with candidates ready to interview
                  </p>
                </div>
                <div class="relative z-30 mx-auto">
                  <div class="group/card h-full border-2 border-white/10 bg-muted group relative flex-1 overflow-hidden rounded-xl">
                    <div class="grid h-7 grid-cols-[1fr_auto_1fr] overflow-hidden border-b border-gray-800">
                      <div class="ml-2 flex items-center gap-1">
                        <div class="h-2.5 w-2.5 rounded-full bg-red-400"></div>
                        <div class="h-2.5 w-2.5 rounded-full bg-yellow-400"></div>
                        <div class="h-2.5 w-2.5 rounded-full bg-green-400"></div>
                      </div>
                      <div class="flex items-center justify-center gap-2">
                        <img src={~p"/images/logos/slack.svg"} alt="Slack" class="w-4 h-4 rounded" />
                        <div class="text-xs text-foreground">
                          app.slack.com<span class="text-foreground/70">/client/T05UQ2UMHFX/C09FC54M0S3</span>
                        </div>
                      </div>
                      <div></div>
                    </div>
                    <div class="relative flex aspect-[1008/561] h-full w-full items-center justify-center">
                      <img
                        src={~p"/images/screenshots/candidate-drip.png"}
                        alt="Candidate drip"
                        class="w-full bg-[#121214] p-1"
                      />
                    </div>
                  </div>
                </div>
              </div>
              <div class="w-full space-y-4">
                <div class="flex items-start gap-2 sm:gap-3">
                  <.icon name="tabler-circle-number-3" class="w-6 h-6 text-foreground shrink-0" />
                  <p class="text-foreground text-sm sm:text-base font-medium">
                    Candidates are auto-added to your Ashby
                  </p>
                </div>
                <div class="relative z-30 mx-auto">
                  <div class="group/card h-full border-2 border-white/10 bg-muted group relative flex-1 overflow-hidden rounded-xl">
                    <div class="grid h-7 grid-cols-[1fr_auto_1fr] overflow-hidden border-b border-gray-800">
                      <div class="ml-2 flex items-center gap-1">
                        <div class="h-2.5 w-2.5 rounded-full bg-red-400"></div>
                        <div class="h-2.5 w-2.5 rounded-full bg-yellow-400"></div>
                        <div class="h-2.5 w-2.5 rounded-full bg-green-400"></div>
                      </div>
                      <div class="flex items-center justify-center gap-2">
                        <img src={~p"/images/logos/ashby.png"} alt="Ashby" class="w-4 h-4 rounded" />
                        <div class="text-xs text-foreground">
                          app.ashbyhq.com<span class="text-foreground/70">/candidates/pipeline/active</span>
                        </div>
                      </div>
                      <div></div>
                    </div>
                    <div class="relative flex aspect-[816/414] h-full w-full items-center justify-center">
                      <img src={~p"/images/screenshots/ashby.png"} alt="Ashby" class="w-full" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    authorize_url =
      case params["return_to"] do
        nil -> Algora.Github.authorize_url()
        return_to -> Algora.Github.authorize_url(%{return_to: return_to})
      end

    changeset = User.login_changeset(%User{}, %{})

    {:ok,
     socket
     |> assign(:ip_address, AlgoraWeb.Util.get_ip(socket))
     |> assign(:return_to, params["return_to"])
     |> assign(:authorize_url, authorize_url)
     |> assign(:secret, nil)
     |> assign(:user_type, "company")
     |> assign(:mode, socket.assigns.live_action)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      LocalStore.init(socket,
        key: __MODULE__,
        ok?: &match?(%{secret: _, email: _}, &1),
        checkpoint_url: ~p"/auth/login?#{%{verify: "1", return_to: socket.assigns[:return_to]}}"
      )

    socket = if params["verify"] == "1", do: LocalStore.subscribe(socket), else: socket

    {:noreply, assign(socket, :mode, socket.assigns.live_action)}
  end

  @impl true
  def handle_event("send_login_code", %{"user" => %{"email" => email}}, socket) do
    rate_limit_key = socket.assigns.ip_address

    case Algora.RateLimit.hit("send_otp:#{rate_limit_key}", to_timeout(minute: 1), 3) do
      {:allow, _} ->
        {secret, code} = AlgoraWeb.UserAuth.generate_totp()

        changeset = User.login_changeset(%User{}, %{})

        case Accounts.deliver_totp_signup_email(email, code) do
          {:ok, _id} ->
            {:noreply,
             socket
             |> LocalStore.assign_cached(:secret, secret)
             |> LocalStore.assign_cached(:email, email)
             |> assign_form(changeset)}

          {:error, reason} ->
            Logger.error("Failed to send login code to #{email}: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "We had trouble sending mail to #{email}. Please try again")}
        end

      {:deny, _} ->
        {:noreply, put_flash(socket, :error, "Too many requests. Please try again later.")}
    end
  end

  @impl true
  def handle_event("send_login_code", %{"user" => %{"login_code" => code}}, socket) do
    case AlgoraWeb.UserAuth.verify_totp(socket.assigns.ip_address, socket.assigns.secret, String.trim(code)) do
      :ok ->
        handle =
          socket.assigns.email
          |> Organizations.generate_handle_from_email()
          |> Organizations.ensure_unique_handle()

        user =
          case Repo.get_by(User, email: socket.assigns.email) do
            nil ->
              {:ok, user} =
                %{handle: handle, email: socket.assigns.email}
                |> User.user_registration_changeset()
                |> Repo.insert(returning: true)

              Accounts.auto_join_orgs(user)

              Accounts.ensure_org_context(user)

              user

            user ->
              user
          end

        {:noreply,
         redirect(socket,
           to: AlgoraWeb.UserAuth.generate_login_path(user.email, socket.assigns[:return_to])
         )}

      {:error, :rate_limit_exceeded} ->
        throttle()
        {:noreply, put_flash(socket, :error, "Too many attempts. Please try again later.")}

      {:error, :invalid_totp} ->
        throttle()
        {:noreply, put_flash(socket, :error, "Invalid login code")}
    end
  end

  def handle_event("restore_settings", params, socket) do
    socket = LocalStore.restore(socket, params)

    case socket.assigns[:email] do
      nil -> {:noreply, socket}
      email -> {:noreply, assign(socket, :user, Accounts.get_user_by_email(email))}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp throttle, do: :timer.sleep(1000)
end
