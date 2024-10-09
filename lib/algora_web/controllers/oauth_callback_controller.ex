defmodule AlgoraWeb.OAuthCallbackController do
  use AlgoraWeb, :controller
  require Logger

  alias Algora.Accounts

  def new(conn, %{"provider" => "github", "code" => code, "state" => state} = params) do
    client = github_client(conn)

    with {:ok, info} <- client.exchange_access_token(code: code, state: state),
         %{info: info, primary_email: primary, emails: emails, token: token} = info,
         {:ok, user} <- Accounts.register_github_user(primary, info, emails, token) do
      conn =
        if params["return_to"] do
          conn |> put_session(:user_return_to, params["return_to"])
        else
          conn
        end

      conn
      |> put_flash(:info, "Welcome, #{user.handle}!")
      |> AlgoraWeb.UserAuth.log_in_user(user)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.debug("failed GitHub insert #{inspect(changeset.errors)}")

        conn
        |> put_flash(
          :error,
          "We were unable to fetch the necessary information from your GitHub account"
        )
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

  defp verify_session(conn, key, token) do
    if Plug.Crypto.secure_compare(token, get_session(conn, key)) do
      {:ok, token}
    else
      {:error, "#{key} is invalid"}
    end
  end

  def sign_out(conn, _) do
    AlgoraWeb.UserAuth.log_out_user(conn)
  end

  defp github_client(conn) do
    conn.assigns[:github_client] || Algora.Github
  end
end
