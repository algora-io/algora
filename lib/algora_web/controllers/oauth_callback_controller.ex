defmodule AlgoraWeb.OAuthCallbackController do
  use AlgoraWeb, :controller

  alias Algora.Accounts
  alias Algora.Github

  require Logger

  def translate_error(:invalid), do: "Unable to verify your login request. Please try signing in again"
  def translate_error(:expired), do: "Your login link has expired. Please request a new one to continue"
  def translate_error(%Ecto.Changeset{}), do: "We were unable to fetch the necessary information from your GitHub account"
  def translate_error(_reason), do: "We were unable to contact GitHub. Please try again later"

  def new(conn, %{"provider" => "github", "code" => code, "state" => state}) do
    res = Github.verify_oauth_state(state)

    socket_id =
      case res do
        {:ok, %{socket_id: socket_id}} -> socket_id
        _ -> nil
      end

    type = if(socket_id, do: :popup, else: :redirect)

    with {:ok, data} <- res,
         {:ok, info} <- Github.OAuth.exchange_access_token(code: code, state: state),
         %{info: info, primary_email: primary, emails: emails, token: token} = info,
         {:ok, user} <- Accounts.register_github_user(conn.assigns[:current_user], primary, info, emails, token) do
      if socket_id do
        Phoenix.PubSub.broadcast(Algora.PubSub, "auth:#{socket_id}", {:authenticated, user})
      end

      case type do
        :popup ->
          conn
          |> AlgoraWeb.UserAuth.put_current_user(user)
          |> render(:success)

        :redirect ->
          conn = AlgoraWeb.UserAuth.put_current_user(conn, user)
          AlgoraWeb.Util.redirect_safe(conn, data[:return_to] || AlgoraWeb.UserAuth.signed_in_path(conn))
      end
    else
      {:error, reason} ->
        Logger.error("failed GitHub exchange #{inspect(reason)}")
        conn = put_flash(conn, :error, translate_error(reason))

        case type do
          :popup ->
            render(conn, :error)

          :redirect ->
            redirect(conn, to: "/")
        end
    end
  end

  def new(conn, %{"provider" => "github", "error" => "access_denied"}) do
    redirect(conn, to: "/")
  end

  def new(conn, %{"provider" => "email", "email" => email, "token" => token} = params) do
    with {:ok, _login_token} <- AlgoraWeb.UserAuth.verify_login_code(token, email),
         {:ok, user} <- get_or_register_user(email) do
      conn =
        if params["return_to"] do
          put_session(conn, :user_return_to, String.trim_leading(params["return_to"], AlgoraWeb.Endpoint.url()))
        else
          conn
        end

      AlgoraWeb.UserAuth.log_in_user(conn, user)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.debug("failed GitHub insert #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, "Something went wrong. Please try again.")
        |> redirect(to: "/")

      {:error, reason} ->
        Logger.debug("failed GitHub exchange #{inspect(reason)}")

        conn
        |> put_flash(:error, "Something went wrong. Please try again.")
        |> redirect(to: "/")
    end
  end

  def sign_out(conn, _) do
    AlgoraWeb.UserAuth.log_out_user(conn)
  end

  defp get_or_register_user(email) do
    case Accounts.get_user_by_email(email) do
      nil -> Accounts.register_org(%{email: email})
      user -> {:ok, user}
    end
  end
end
