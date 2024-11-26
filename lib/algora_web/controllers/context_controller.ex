defmodule AlgoraWeb.ContextController do
  use AlgoraWeb, :controller
  alias Algora.Users
  alias AlgoraWeb.UserAuth

  def set(conn, %{"context" => context}) do
    {:ok, _updated_user} =
      Users.update_settings(conn.assigns.current_user, %{last_context: context})

    conn = put_session(conn, :last_context, context)

    redirect(conn, to: UserAuth.signed_in_path(conn))
  end
end
