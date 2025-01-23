defmodule AlgoraWeb.SignInLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts.User
  alias Swoosh.Email

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <div class="min-h-[calc(100vh-64px)] flex flex-col justify-center">
        <div class="mb mx-auto max-w-3xl p-4 sm:mx-auto sm:w-full sm:max-w-sm">
          <h2 class="text-center text-3xl font-extrabold text-gray-50 p-4">
            Algora Console
          </h2>
          <.header class="text-center p-4">
            Sign in with Github
            <:subtitle>Sign in and link your Github Account</:subtitle>
          </.header>
          <.link
            href={@authorize_url}
            rel="noopener"
            class="mt-4 flex w-full justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2"
          >
            Authorize with GitHub
          </.link>
        </div>
        <div class="border-t border-gray-800 my-4"></div>
        <.header class="text-center p-4">
          Sign in with Email
          <:subtitle :if={!@secret_code}>We'll send a login code to your inbox</:subtitle>
          <:subtitle :if={@secret_code}>We sent a login code to your inbox</:subtitle>
        </.header>

        <.simple_form for={@form} id="send_login_code_form" phx-submit="send_login_code">
          <.input :if={!@secret_code} field={@form[:email]} type="email" placeholder="Email" required />
          <.input
            :if={@secret_code}
            field={@form[:login_code]}
            type="text"
            placeholder="Enter Login Code"
            required
          />
          <:actions>
            <.button
              if={!@secret_code}
              phx-disable-with="Sending..."
              class="mt-4 flex w-full justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2"
            >
              <span :if={!@secret_code}>Send login code</span>
              <div :if={@secret_code}>Login with code</div>
            </.button>
          </:actions>
        </.simple_form>
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
        case send_login_code_to_user!(user, code) do
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
      {:noreply, put_flash(socket, :info, "Invalid login code")}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @from_name "Algora"
  @from_email "info@algora.io"

  defp send_login_code_to_user!(user, code) do
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
