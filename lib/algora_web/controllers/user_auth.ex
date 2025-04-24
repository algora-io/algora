defmodule AlgoraWeb.UserAuth do
  @moduledoc false
  use AlgoraWeb, :verified_routes

  import Phoenix.Controller
  import Plug.Conn

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Phoenix.LiveView

  defp login_code_ttl, do: Algora.config([:login_code, :ttl])
  defp login_code_salt, do: Algora.config([:login_code, :salt])

  def on_mount(:current_user, _params, session, socket) do
    case session do
      %{"user_id" => user_id} ->
        case socket.assigns[:current_user] do
          %Accounts.User{} = _user ->
            {:cont, socket}

          nil ->
            current_user = Accounts.get_user(user_id)
            current_context = Accounts.get_last_context_user(current_user)
            all_contexts = Accounts.get_contexts(current_user)

            {:cont,
             socket
             |> Phoenix.Component.assign(:current_user, current_user)
             |> Phoenix.Component.assign(:current_context, current_context)
             |> Phoenix.Component.assign(:all_contexts, all_contexts)}
        end

      %{} ->
        {:cont, Phoenix.Component.assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    case get_authenticated_user(session, socket) do
      {:ok, user} ->
        {:cont,
         socket
         |> Phoenix.Component.assign_new(:current_user, fn -> user end)
         |> Phoenix.Component.assign_new(:current_context, fn -> Accounts.get_last_context_user(user) end)
         |> Phoenix.Component.assign_new(:all_contexts, fn -> Accounts.get_contexts(user) end)}

      {:error, :unauthenticated} ->
        {:halt, redirect_require_login(socket)}
    end
  end

  def on_mount(:ensure_admin, _params, session, socket) do
    case get_authenticated_user(session, socket) do
      {:ok, user} ->
        if not user.is_admin do
          raise(AlgoraWeb.NotFoundError)
        end

        {:cont,
         socket
         |> Phoenix.Component.assign_new(:current_user, fn -> user end)
         |> Phoenix.Component.assign_new(:current_context, fn -> Accounts.get_last_context_user(user) end)
         |> Phoenix.Component.assign_new(:all_contexts, fn -> Accounts.get_contexts(user) end)}

      {:error, :unauthenticated} ->
        {:halt, redirect_require_login(socket)}
    end
  end

  defp get_authenticated_user(session, socket) do
    case session do
      %{"user_id" => user_id} ->
        new_socket = Phoenix.Component.assign_new(socket, :current_user, fn -> Accounts.get_user!(user_id) end)

        case new_socket.assigns[:current_user] do
          %Accounts.User{} = user ->
            {:ok, user}

          nil ->
            {:error, :unauthenticated}
        end

      %{} ->
        {:error, :unauthenticated}
    end
  rescue
    Ecto.NoResultsError -> {:error, :unauthenticated}
  end

  defp redirect_require_login(socket) do
    redirect_url =
      case socket.private.connect_info.request_path do
        nil -> ~p"/auth/login"
        request_path -> ~p"/auth/login?#{%{return_to: request_path}}"
      end

    LiveView.redirect(socket, to: redirect_url)
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

    conn
    |> put_current_user(user)
    |> AlgoraWeb.Util.redirect_safe(user_return_to || signed_in_path(user))
  end

  def put_current_user(conn, user) do
    conn =
      conn
      |> assign(:current_user, user)
      |> assign(:current_context, Accounts.get_last_context_user(user))
      |> assign(:all_contexts, Accounts.get_contexts(user))

    conn
    |> renew_session()
    |> put_session(:user_id, user.id)
    |> put_session(:last_context, Accounts.last_context(user))
    |> put_session(:live_socket_id, "users_sessions:#{user.id}")
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
    user = user_id && Accounts.get_user(user_id)

    if user do
      Task.start(fn ->
        user
        |> Ecto.Changeset.change(last_active_at: DateTime.utc_now())
        |> Algora.Repo.update()

        Algora.Repo.insert_activity(user, %{type: :user_online, notify_users: []})
      end)
    end

    conn
    |> assign(:current_user, user)
    |> assign(:current_context, Accounts.get_last_context_user(user))
    |> assign(:all_contexts, Accounts.get_contexts(user))
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

    if user && user.is_admin do
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

  def signed_in_path_from_context("personal"), do: ~p"/home"

  def signed_in_path_from_context("preview/" <> ctx) do
    case String.split(ctx, "/") do
      [_id, repo_owner, repo_name] -> ~p"/go/#{repo_owner}/#{repo_name}"
      _ -> ~p"/home"
    end
  end

  def signed_in_path_from_context(org_handle), do: ~p"/#{org_handle}/dashboard"

  def signed_in_path(%User{} = user) do
    signed_in_path_from_context(Accounts.last_context(user))
  end

  def signed_in_path(conn) do
    cond do
      last_context = get_session(conn, :last_context) ->
        signed_in_path_from_context(last_context)

      user = conn.assigns[:current_user] ->
        signed_in_path(user)

      true ->
        signed_in_path_from_context(Accounts.default_context())
    end
  end

  def generate_login_code(email) do
    sign_login_code(email)
  end

  def generate_login_code(email, domain, tech_stack) do
    sign_login_code("#{email}:#{domain || ""}:#{Enum.join(tech_stack, ":")}")
  end

  def sign_login_code(payload) do
    Phoenix.Token.sign(AlgoraWeb.Endpoint, login_code_salt(), payload, max_age: login_code_ttl())
  end

  def verify_login_code(nil, _email), do: {:error, :missing}

  def verify_login_code(code, email) do
    code = String.trim(code || "")

    case Phoenix.Token.verify(AlgoraWeb.Endpoint, login_code_salt(), code, max_age: login_code_ttl()) do
      {:ok, payload} ->
        result =
          case String.split(payload, ":") do
            [email, domain | tech_stack] ->
              {:ok,
               %{
                 email: email,
                 domain: if(domain != "", do: domain),
                 tech_stack: Enum.reject(tech_stack, &(&1 == "")),
                 token: code
               }}

            [email] ->
              {:ok, %{email: email, token: code}}

            _other ->
              {:error, :invalid_payload}
          end

        case result do
          {:ok, data} ->
            if data.email == email do
              {:ok, data}
            else
              {:error, :invalid_email}
            end

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def sign_preview_code(payload) do
    Phoenix.Token.sign(AlgoraWeb.Endpoint, login_code_salt(), payload, max_age: login_code_ttl())
  end

  def verify_preview_code(nil, _id), do: {:error, :missing}

  def verify_preview_code(code, id) do
    code = String.trim(code || "")

    case Phoenix.Token.verify(AlgoraWeb.Endpoint, login_code_salt(), code, max_age: login_code_ttl()) do
      {:ok, token_id} ->
        if token_id == id do
          {:ok, token_id}
        else
          {:error, :invalid_id}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def preview_path(id, token), do: ~p"/preview?id=#{id}&token=#{token}"

  def preview_path(id, token, return_to), do: ~p"/preview?id=#{id}&token=#{token}&return_to=#{return_to}"

  def login_path(email, token), do: ~p"/callbacks/email/oauth?email=#{email}&token=#{token}"
  def login_path(email, token, nil), do: ~p"/callbacks/email/oauth?email=#{email}&token=#{token}"

  def login_path(email, token, return_to),
    do: ~p"/callbacks/email/oauth?email=#{email}&token=#{token}&return_to=#{return_to}"

  def generate_login_path(email, return_to \\ nil), do: login_path(email, generate_login_code(email), return_to)

  def generate_totp do
    secret = NimbleTOTP.secret()
    code = NimbleTOTP.verification_code(secret, period: totp_period())
    {secret, code}
  end

  defp totp_period, do: 300

  def valid_totp?(secret, code) do
    time = System.os_time(:second)

    is_binary(code) and byte_size(code) == 6 and
      (NimbleTOTP.valid?(secret, code, period: totp_period(), time: time) or
         NimbleTOTP.valid?(secret, code, period: totp_period(), time: time - totp_period()))
  end

  def verify_totp(rate_limit_key, secret, code) do
    case Algora.RateLimit.hit("verify_totp:#{rate_limit_key}", :timer.minutes(1), 5) do
      {:allow, _} ->
        if valid_totp?(secret, code) do
          :ok
        else
          {:error, :invalid_totp}
        end

      {:deny, _} ->
        {:error, :rate_limit_exceeded}
    end
  end
end
