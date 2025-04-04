defmodule AlgoraWeb.SignInLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts.User
  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.LocalStore
  alias Swoosh.Email

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-[100svh] bg-[#111113]" id="sign-in-page" phx-hook="LocalStateStore">
      <div class="relative flex flex-1 flex-col justify-center px-4 py-16 sm:px-6 lg:flex-none lg:px-20 xl:px-24 lg:border-r lg:border-border">
        <.wordmark class="h-10 w-auto absolute top-4 left-4 sm:top-8 sm:left-8" />
        <div class="mx-auto w-full max-w-sm lg:w-96 h-auto flex flex-col min-h-[426px]">
          <div :if={!@secret_code}>
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

          <div :if={@secret_code}>
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
                :if={!@secret_code}
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
              <.button :if={!@secret_code} href={@authorize_url} class="w-full py-5">
                <Logos.github class="size-5 mr-2 -ml-1 shrink-0" /> Continue with GitHub
              </.button>
            </div>

            <.simple_form
              :if={@secret_code}
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

          <div :if={!@secret_code} class="mt-8 text-center text-sm text-muted-foreground">
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
        <div class="absolute inset-0 flex flex-col items-center justify-center bg-background p-12">
          <div :if={@random_quote} class="max-w-xl">
            <div class="relative text-base">
              <svg
                viewBox="0 0 162 128"
                fill="none"
                aria-hidden="true"
                class="absolute -top-12 left-0 h-32 stroke-white/25"
              >
                <path
                  id="b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb"
                  d="M65.5697 118.507L65.8918 118.89C68.9503 116.314 71.367 113.253 73.1386 109.71C74.9162 106.155 75.8027 102.28 75.8027 98.0919C75.8027 94.237 75.16 90.6155 73.8708 87.2314C72.5851 83.8565 70.8137 80.9533 68.553 78.5292C66.4529 76.1079 63.9476 74.2482 61.0407 72.9536C58.2795 71.4949 55.276 70.767 52.0386 70.767C48.9935 70.767 46.4686 71.1668 44.4872 71.9924L44.4799 71.9955L44.4726 71.9988C42.7101 72.7999 41.1035 73.6831 39.6544 74.6492C38.2407 75.5916 36.8279 76.455 35.4159 77.2394L35.4047 77.2457L35.3938 77.2525C34.2318 77.9787 32.6713 78.3634 30.6736 78.3634C29.0405 78.3634 27.5131 77.2868 26.1274 74.8257C24.7483 72.2185 24.0519 69.2166 24.0519 65.8071C24.0519 60.0311 25.3782 54.4081 28.0373 48.9335C30.703 43.4454 34.3114 38.345 38.8667 33.6325C43.5812 28.761 49.0045 24.5159 55.1389 20.8979C60.1667 18.0071 65.4966 15.6179 71.1291 13.7305C73.8626 12.8145 75.8027 10.2968 75.8027 7.38572C75.8027 3.6497 72.6341 0.62247 68.8814 1.1527C61.1635 2.2432 53.7398 4.41426 46.6119 7.66522C37.5369 11.6459 29.5729 17.0612 22.7236 23.9105C16.0322 30.6019 10.618 38.4859 6.47981 47.558L6.47976 47.558L6.47682 47.5647C2.4901 56.6544 0.5 66.6148 0.5 77.4391C0.5 84.2996 1.61702 90.7679 3.85425 96.8404L3.8558 96.8445C6.08991 102.749 9.12394 108.02 12.959 112.654L12.959 112.654L12.9646 112.661C16.8027 117.138 21.2829 120.739 26.4034 123.459L26.4033 123.459L26.4144 123.465C31.5505 126.033 37.0873 127.316 43.0178 127.316C47.5035 127.316 51.6783 126.595 55.5376 125.148L55.5376 125.148L55.5477 125.144C59.5516 123.542 63.0052 121.456 65.9019 118.881L65.5697 118.507Z"
                >
                </path>
                <use href="#b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb" x="86"></use>
              </svg>
              <blockquote class="text-3xl font-medium text-foreground">
                {@random_quote.text}
              </blockquote>
            </div>

            <div class="mt-8 flex items-center gap-4">
              <div class="size-12 overflow-hidden rounded-full bg-muted">
                <img src={@random_quote.avatar} alt="Avatar" class="h-full w-full object-cover" />
              </div>
              <div>
                <div class="font-medium text-foreground">{@random_quote.author}</div>
                <div class="text-sm text-muted-foreground">{@random_quote.role}</div>
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

    socket =
      if connected?(socket) do
        assign(socket, :random_quote, get_random_quote())
      else
        assign(socket, :random_quote, nil)
      end

    {:ok,
     socket
     |> assign(:authorize_url, authorize_url)
     |> assign(:secret_code, nil)
     |> assign(:user_type, "company")
     |> assign(:mode, socket.assigns.live_action)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      LocalStore.init(socket,
        key: __MODULE__,
        ok?: &match?(%{secret_code: _, email: _}, &1),
        checkpoint_url: ~p"/auth/login?#{%{verify: "1", return_to: socket.assigns[:return_to]}}"
      )

    socket = if params["verify"] == "1", do: LocalStore.subscribe(socket), else: socket

    socket =
      socket
      |> assign(:return_to, params["return_to"])
      |> assign(:mode, socket.assigns.live_action)

    {:noreply, socket}
  end

  @impl true
  def handle_event("send_login_code", %{"user" => %{"email" => email}}, socket) do
    code = Nanoid.generate()

    case Algora.Accounts.get_user_by_email(email) do
      %User{} = user ->
        changeset = User.login_changeset(%User{}, %{})

        case send_login_code_to_user(user, code) do
          {:ok, _id} ->
            {:noreply,
             socket
             |> LocalStore.assign_cached(:secret_code, code)
             |> LocalStore.assign_cached(:email, email)
             |> assign(:user, user)
             |> assign_form(changeset)}

          {:error, _reason} ->
            # capture_error reason
            {:noreply,
             put_flash(
               socket,
               :error,
               "We had trouble sending mail to #{email}. Please try again"
             )}
        end

      nil ->
        throttle()
        {:noreply, put_flash(socket, :error, "Email address not found.")}
    end
  end

  @impl true
  def handle_event("send_login_code", %{"user" => %{"login_code" => code}}, socket) do
    if Plug.Crypto.secure_compare(String.trim(code), socket.assigns.secret_code) do
      {:noreply,
       redirect(socket, to: AlgoraWeb.UserAuth.generate_login_path(socket.assigns.user.email, socket.assigns[:return_to]))}
    else
      throttle()
      {:noreply, put_flash(socket, :error, "Invalid login code")}
    end
  end

  def handle_event("restore_settings", params, socket) do
    socket = LocalStore.restore(socket, params)

    case socket.assigns[:email] do
      nil -> {:noreply, socket}
      email -> {:noreply, assign(socket, :user, Algora.Accounts.get_user_by_email(email))}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @from_name "Algora"
  @from_email "info@algora.io"

  defp send_login_code_to_user(user, code) do
    email =
      Email.new()
      |> Email.to({user.display_name, user.email})
      |> Email.from({@from_name, @from_email})
      |> Email.subject("Login code for Algora")
      |> Email.text_body("""
      Here is your login code for Algora!

       #{code}

      If you didn't request this link, you can safely ignore this email.

      --------------------------------------------------------------------------------

      For correspondence, please email the Algora founders at ioannis@algora.io and zafer@algora.io

      © 2025 Algora PBC.
      """)

    Algora.Mailer.deliver(email)
  end

  defp throttle, do: :timer.sleep(1000)

  defp get_random_quote do
    Enum.random([
      %{
        text:
          "That's one massive advantage open source companies have versus closed source. You get to show people your work, plus you can point to your contributions as proof of your abilities.",
        author: "Eric Allam",
        role: "Founder & CTO, Trigger.dev (YC W23)",
        avatar: ~p"/images/people/eric-allam.jpg"
      },
      %{
        text:
          "We've used Algora extensively at Golem Cloud for our hiring needs. Many times someone who is very active in open-source development, these types of engineers often make fantastic additions to a team.",
        author: "John A. De Goes",
        role: "Founder & CEO, Golem Cloud",
        avatar: ~p"/images/people/john-de-goes-2.jpg"
      },
      %{
        text:
          "We were doing bounties on Algora, and this one developer Nick kept solving them. His personality really came through in the GitHub issues and code. We ended up hiring him from that.",
        author: "Eric Allam",
        role: "Founder & CTO, Trigger.dev (YC W23)",
        avatar: ~p"/images/people/eric-allam.jpg"
      },
      %{
        text:
          "The majority of work is done by open source contributors, that's how it's built today. And that sort of helps us control our burn rate. You get paid if you get a pull request merged.",
        author: "Tushar Mathur",
        role: "Founder & CEO, Tailcall",
        avatar: "https://avatars.githubusercontent.com/u/194482?v=4"
      },
      %{
        text:
          "A GitHub issue is this atomic unit of a problem, and allowing you to put a cash bounty on it, to solve this specific problem, without any overhead, and make it available to any person, I find it very interesting.",
        author: "Jonny Burger",
        role: "Founder, Remotion",
        avatar: "https://avatars.githubusercontent.com/u/1629785?v=4"
      },
      %{
        text:
          "I certainly believe people should be compensated for their time, especially if we commercially benefit from it. When possible we should offer some sort of compensation.",
        author: "Josh Pigford",
        role: "Co-founder & CEO, Maybe",
        avatar: "https://avatars.githubusercontent.com/u/35243?v=4"
      }
    ])
  end
end
