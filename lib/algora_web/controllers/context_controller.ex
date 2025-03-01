defmodule AlgoraWeb.ContextController do
  use AlgoraWeb, :controller

  alias Algora.Accounts
  alias AlgoraWeb.UserAuth

  def set(conn, %{"context" => context}) do
    # TODO: validate context is accessible by user

    conn =
      case Accounts.update_settings(conn.assigns.current_user, %{last_context: context}) do
        {:ok, user} -> assign(conn, :current_user, user)
        {:error, _} -> conn
      end

    conn
    |> put_session(:last_context, context)
    |> redirect(to: UserAuth.signed_in_path_from_context(context))
  end
end
