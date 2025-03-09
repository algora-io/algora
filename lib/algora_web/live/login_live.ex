defmodule AlgoraWeb.LoginLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts.User
  alias Swoosh.Email

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen bg-background">
      <div class="flex flex-1 flex-col justify-center px-4 py-12 sm:px-6 lg:flex-none lg:px-20 xl:px-24">
        <div class="mx-auto w-full max-w-sm lg:w-96">
          <div>
            <img
              class="h-10 w-auto"
              src="https://tailwindcss.com/plus-assets/img/logos/mark.svg?color=indigo&shade=600"
              alt="Your Company"
            />
            <h2 class="mt-8 text-2xl/9 font-bold tracking-tight text-foreground">
              Sign in to your account
            </h2>
            <p class="mt-2 text-sm/6 text-muted-foreground">
              Not a member?
              <a href="#" class="font-semibold text-primary hover:text-primary/90">
                Start a 14 day free trial
              </a>
            </p>
          </div>

          <div class="mt-10">
            <div>
              <form action="#" method="POST" class="space-y-6">
                <div>
                  <label for="email" class="block text-sm/6 font-medium text-foreground">
                    Email address
                  </label>
                  <div class="mt-2">
                    <input
                      type="email"
                      name="email"
                      id="email"
                      autocomplete="email"
                      required
                      class="block w-full rounded-md bg-background px-3 py-1.5 text-base text-foreground ring-1 ring-inset ring-input placeholder:text-muted-foreground focus-visible:ring-2 focus-visible:ring-primary sm:text-sm/6"
                    />
                  </div>
                </div>

                <div>
                  <label for="password" class="block text-sm/6 font-medium text-foreground">
                    Password
                  </label>
                  <div class="mt-2">
                    <input
                      type="password"
                      name="password"
                      id="password"
                      autocomplete="current-password"
                      required
                      class="block w-full rounded-md bg-background px-3 py-1.5 text-base text-foreground ring-1 ring-inset ring-input placeholder:text-muted-foreground focus-visible:ring-2 focus-visible:ring-primary sm:text-sm/6"
                    />
                  </div>
                </div>

                <div class="flex items-center justify-between">
                  <div class="flex gap-3">
                    <div class="flex h-6 shrink-0 items-center">
                      <div class="group grid size-4 grid-cols-1">
                        <input
                          id="remember-me"
                          name="remember-me"
                          type="checkbox"
                          class="col-start-1 row-start-1 appearance-none rounded border border-input bg-background checked:border-primary checked:bg-primary focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:border-input disabled:bg-muted"
                        />
                        <svg
                          class="pointer-events-none col-start-1 row-start-1 size-3.5 self-center justify-self-center stroke-primary-foreground group-has-[:disabled]:stroke-muted-foreground/25"
                          viewBox="0 0 14 14"
                          fill="none"
                        >
                          <path
                            class="opacity-0 group-has-[:checked]:opacity-100"
                            d="M3 8L6 11L11 3.5"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          />
                          <path
                            class="opacity-0 group-has-[:indeterminate]:opacity-100"
                            d="M3 7H11"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          />
                        </svg>
                      </div>
                    </div>
                    <label for="remember-me" class="block text-sm/6 text-foreground">
                      Remember me
                    </label>
                  </div>

                  <div class="text-sm/6">
                    <a href="#" class="font-semibold text-primary hover:text-primary/90">
                      Forgot password?
                    </a>
                  </div>
                </div>

                <div>
                  <button
                    type="submit"
                    class="flex w-full justify-center rounded-md bg-primary px-3 py-1.5 text-sm/6 font-semibold text-primary-foreground shadow hover:bg-primary/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                  >
                    Sign in
                  </button>
                </div>
              </form>
            </div>

            <div class="mt-10">
              <div class="relative">
                <div class="absolute inset-0 flex items-center" aria-hidden="true">
                  <div class="w-full border-t border-border"></div>
                </div>
                <div class="relative flex justify-center text-sm/6 font-medium">
                  <span class="bg-background px-6 text-muted-foreground">Or continue with</span>
                </div>
              </div>

              <div class="mt-6 grid grid-cols-2 gap-4">
                <a
                  href="#"
                  class="flex w-full items-center justify-center gap-3 rounded-md bg-background px-3 py-2 text-sm font-semibold text-foreground ring-1 ring-inset ring-input hover:bg-accent focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                >
                  <svg class="h-5 w-5" viewBox="0 0 24 24" aria-hidden="true">
                    <path
                      d="M12.0003 4.75C13.7703 4.75 15.3553 5.36002 16.6053 6.54998L20.0303 3.125C17.9502 1.19 15.2353 0 12.0003 0C7.31028 0 3.25527 2.69 1.28027 6.60998L5.27028 9.70498C6.21525 6.86002 8.87028 4.75 12.0003 4.75Z"
                      fill="#EA4335"
                    />
                    <path
                      d="M23.49 12.275C23.49 11.49 23.415 10.73 23.3 10H12V14.51H18.47C18.18 15.99 17.34 17.25 16.08 18.1L19.945 21.1C22.2 19.01 23.49 15.92 23.49 12.275Z"
                      fill="#4285F4"
                    />
                    <path
                      d="M5.26498 14.2949C5.02498 13.5699 4.88501 12.7999 4.88501 11.9999C4.88501 11.1999 5.01998 10.4299 5.26498 9.7049L1.275 6.60986C0.46 8.22986 0 10.0599 0 11.9999C0 13.9399 0.46 15.7699 1.28 17.3899L5.26498 14.2949Z"
                      fill="#FBBC05"
                    />
                    <path
                      d="M12.0004 24.0001C15.2404 24.0001 17.9654 22.935 19.9454 21.095L16.0804 18.095C15.0054 18.82 13.6204 19.245 12.0004 19.245C8.8704 19.245 6.21537 17.135 5.2654 14.29L1.27539 17.385C3.25539 21.31 7.3104 24.0001 12.0004 24.0001Z"
                      fill="#34A853"
                    />
                  </svg>
                  <span class="text-sm/6 font-semibold">Google</span>
                </a>

                <a
                  href="#"
                  class="flex w-full items-center justify-center gap-3 rounded-md bg-background px-3 py-2 text-sm font-semibold text-foreground ring-1 ring-inset ring-input hover:bg-accent focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                >
                  <svg
                    class="size-5 fill-[#24292F]"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M10 0C4.477 0 0 4.484 0 10.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0110 4.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.942.359.31.678.921.678 1.856 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0020 10.017C20 4.484 15.522 0 10 0z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  <span class="text-sm/6 font-semibold">GitHub</span>
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="relative hidden w-0 flex-1 lg:block">
        <img
          class="absolute inset-0 size-full object-cover"
          src="https://images.unsplash.com/photo-1496917756835-20cb06e75b4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1908&q=80"
          alt=""
        />
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    authorize_url =
      case params["return_to"] do
        nil -> Algora.Github.authorize_url()
        return_to -> Algora.Github.authorize_url(%{return_to: return_to})
      end

    changeset = User.login_changeset(%User{}, %{})

    {:ok,
     socket
     |> assign(authorize_url: authorize_url)
     |> assign(secret_code: nil)
     |> assign_form(changeset)}
  end

  def handle_event("send_login_code", %{"user" => %{"email" => email}}, socket) do
    code = Nanoid.generate()

    case Algora.Accounts.get_user_by_email(email) do
      %User{} = user ->
        changeset = User.login_changeset(%User{}, %{})

        case send_login_code_to_user(user, code) do
          {:ok, _id} ->
            {:noreply,
             socket
             |> assign(:secret_code, code)
             |> assign(:user, user)
             |> assign_form(changeset)
             |> put_flash(:info, "Login code sent to #{email}!")}

          {:error, _reason} ->
            # capture_error reason
            {:noreply, put_flash(socket, :error, "We had trouble sending mail to #{email}. Please try again")}
        end

      nil ->
        throttle()
        {:noreply, put_flash(socket, :error, "Email address not found.")}
    end
  end

  def handle_event("send_login_code", %{"user" => %{"login_code" => code}}, socket) do
    if Plug.Crypto.secure_compare(code, socket.assigns.secret_code) do
      user = socket.assigns.user
      token = AlgoraWeb.UserAuth.generate_login_code(user.email)
      path = AlgoraWeb.UserAuth.login_path(user.email, token)

      {:noreply,
       socket
       |> redirect(to: path)
       |> put_flash(:info, "Logged in successfully!")}
    else
      throttle()
      {:noreply, put_flash(socket, :error, "Invalid login code")}
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
end
