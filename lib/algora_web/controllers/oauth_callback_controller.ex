defmodule AlgoraWeb.OAuthCallbackController do
  use AlgoraWeb, :controller

  alias Algora.Accounts
  alias Algora.Github

  require Logger

  defp welcome_message(user) do
    if user.name do
      "Welcome, #{user.name |> String.split() |> List.first() |> String.capitalize()}!"
    else
      "Welcome, #{user.handle}!"
    end
  end

  def new(conn, %{"provider" => "github", "code" => code, "state" => state}) do
    with {:ok, data} <- Github.verify_oauth_state(state),
         {:ok, info} <- Github.OAuth.exchange_access_token(code: code, state: state),
         %{info: info, primary_email: primary, emails: emails, token: token} = info,
         {:ok, user} <- Accounts.register_github_user(primary, info, emails, token) do
      conn =
        case data[:return_to] do
          nil -> conn
          return_to -> put_session(conn, :user_return_to, return_to)
        end

      conn
      |> put_flash(:info, welcome_message(user))
      |> AlgoraWeb.UserAuth.log_in_user(user)
    else
      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Unable to verify your login request. Please try signing in again.")
        |> redirect(to: "/")

      {:error, :expired} ->
        conn
        |> put_flash(:error, "Your login link has expired. Please request a new one to continue.")
        |> redirect(to: "/")

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.debug("failed GitHub insert #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, "We were unable to fetch the necessary information from your GitHub account")
        |> redirect(to: "/")

      {:error, reason} ->
        Logger.debug("failed GitHub exchange #{inspect(reason)}")

        conn
        |> put_flash(:error, "We were unable to contact GitHub. Please try again later")
        |> redirect(to: "/")
    end
  end

  def new(conn, %{"provider" => "github", "error" => "access_denied"}) do
    redirect(conn, to: "/")
  end

  def new(conn, %{"provider" => "email", "email" => email, "token" => token, "return_to" => "/onboarding/org"}) do
    case AlgoraWeb.UserAuth.verify_login_code(token) do
      {:ok, %{email: ^email} = login_token} ->
        conn
        |> put_session(:onboarding_email, login_token.email)
        |> put_session(:onboarding_domain, login_token.domain)
        |> put_session(:onboarding_tech_stack, Enum.join(login_token.tech_stack, ","))
        |> put_session(:onboarding_token, token)
        |> redirect(to: "/onboarding/org")

      {:error, reason} ->
        Logger.debug("invalid email auth token #{inspect(reason)}")

        conn
        |> put_flash(:error, "Invalid token")
        |> redirect(to: "/")
    end
  end

  def new(conn, %{"provider" => "email", "email" => email, "token" => token} = params) do
    with {:ok, %{email: ^email}} <- AlgoraWeb.UserAuth.verify_login_code(token),
         {:ok, user} <- get_or_register_user(email) do
      conn =
        if params["return_to"] do
          put_session(conn, :user_return_to, params["return_to"])
        else
          conn
        end

      conn
      |> put_flash(:info, welcome_message(user))
      |> AlgoraWeb.UserAuth.log_in_user(user)
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
