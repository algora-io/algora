defmodule AlgoraWeb.OrgPreviewCallbackController do
  use AlgoraWeb, :controller

  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Repo

  require Logger

  def new(conn, %{"id" => id, "token" => token} = params) do
    with {:ok, _login_token} <- AlgoraWeb.UserAuth.verify_preview_code(token, id),
         {:ok, user} <-
           Repo.fetch_one(
             from u in User,
               where: u.id == ^id,
               where: is_nil(u.handle),
               where: is_nil(u.provider_login)
           ) do
      conn =
        if params["return_to"] do
          put_session(conn, :user_return_to, String.trim_leading(params["return_to"], AlgoraWeb.Endpoint.url()))
        else
          conn
        end

      conn
      |> put_flash(:info, "Welcome to Algora!")
      |> AlgoraWeb.UserAuth.log_in_user(user)
    else
      {:error, reason} ->
        Logger.debug("failed preview exchange #{inspect(reason)}")

        conn
        |> put_flash(:error, "Something went wrong. Please try again.")
        |> redirect(to: "/")
    end
  end
end
