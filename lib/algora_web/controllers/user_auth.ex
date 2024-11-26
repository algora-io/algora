defmodule AlgoraWeb.UserAuth do
  use AlgoraWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller

  alias Phoenix.LiveView
  alias Algora.Users

  def on_mount(:current_user, _params, session, socket) do
    case session do
      %{"user_id" => user_id} ->
        {:cont,
         Phoenix.Component.assign_new(socket, :current_user, fn -> Users.get_user(user_id) end)}

      %{} ->
        {:cont, Phoenix.Component.assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    case session do
      %{"user_id" => user_id} ->
        new_socket =
          Phoenix.Component.assign_new(socket, :current_user, fn ->
            Users.get_user!(user_id)
          end)

        %Users.User{} = new_socket.assigns.current_user
        {:cont, new_socket}

      %{} ->
        {:halt, redirect_require_login(socket)}
    end
  rescue
    Ecto.NoResultsError -> {:halt, redirect_require_login(socket)}
  end

  def on_mount(:ensure_admin, _params, session, socket) do
    case session do
      %{"user_id" => user_id} ->
        user = Users.get_user!(user_id)

        if Users.admin?(user) do
          {:cont, socket}
        else
          {:halt, LiveView.redirect(socket, to: ~p"/status/404")}
        end

      %{} ->
        {:halt, redirect_require_login(socket)}
    end
  rescue
    Ecto.NoResultsError -> {:halt, redirect_require_login(socket)}
  end

  defp redirect_require_login(socket) do
    socket
    |> LiveView.put_flash(:error, "Please sign in")
    |> LiveView.redirect(to: ~p"/auth/login")
  end

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user) do
    user_return_to = get_session(conn, :user_return_to)
    conn = assign(conn, :current_user, user)

    conn =
      renew_session(conn)
      |> put_session(:user_id, user.id)
      |> put_session(:last_context, user.last_context)
      |> put_session(:live_socket_id, "users_sessions:#{user.id}")

    redirect(conn, to: user_return_to || signed_in_path(conn))
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    if live_socket_id = get_session(conn, :live_socket_id) do
      AlgoraWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session.
  """
  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = user_id && Users.get_user(user_id)
    assign(conn, :current_user, user)
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/auth/login")
      |> halt()
    end
  end

  def require_authenticated_admin(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && Algora.Users.admin?(user) do
      assign(conn, :current_admin, user)
    else
      conn
      |> put_flash(:error, "You must be logged into access that page")
      |> maybe_store_return_to()
      |> redirect(to: "/")
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    %{request_path: request_path, query_string: query_string} = conn
    return_to = if query_string == "", do: request_path, else: request_path <> "?" <> query_string
    put_session(conn, :user_return_to, return_to)
  end

  defp maybe_store_return_to(conn), do: conn

  def signed_in_path(conn) do
    case get_session(conn, :last_context) do
      nil -> ~p"/dashboard"
      "personal" -> ~p"/dashboard"
      org_handle -> ~p"/org/#{org_handle}"
    end
  end

  defp login_code_ttl, do: 3600
  defp login_code_salt, do: "algora-login-code"

  def generate_login_code(email) do
    Phoenix.Token.sign(AlgoraWeb.Endpoint, login_code_salt(), email, max_age: login_code_ttl())
  end

  def verify_login_code(code) do
    Phoenix.Token.verify(AlgoraWeb.Endpoint, login_code_salt(), code, max_age: login_code_ttl())
  end

  def login_path(email, token),
    do: ~p"/callbacks/email/oauth?email=#{email}&token=#{token}"

  def login_email(email, token) do
    name = email |> String.split("@") |> List.first() |> String.capitalize()

    """
    From: "Algora <info@algora.io>"
    To: "#{email}",
    Subject: "Algora sign-in verification code"

    Hi #{name},

    We have received a login attempt and generated the following verification code:

    #{token}

    To complete the sign-in process, please enter the code above on the page you entered your email address.

    Or copy and paste this URL into your browser:

    #{AlgoraWeb.Endpoint.url()}/#{login_path(email, token)}

    If you didn't request this link, you can safely ignore this email.

    --------------------------------------------------------------------------------

    For correspondence, please email the Algora founders at ioannis@algora.io and zafer@algora.io

    © 2023 Algora PBC.
    """
  end
end
