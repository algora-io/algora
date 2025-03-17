defmodule AlgoraWeb.ContextController do
  use AlgoraWeb, :controller

  alias Algora.Accounts
  alias AlgoraWeb.UserAuth

  def set(conn, %{"context" => context}) do
    case Accounts.set_context(conn.assigns.current_user, context) do
      {:ok, user} ->
        conn
        |> assign(:current_user, user)
        |> put_session(:last_context, context)
        |> redirect(to: UserAuth.signed_in_path_from_context(context))

      {:error, _} ->
        redirect(conn, to: "/")
    end
  end
end
