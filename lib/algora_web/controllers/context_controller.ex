defmodule AlgoraWeb.ContextController do
  use AlgoraWeb, :controller
  alias Algora.Accounts
  alias AlgoraWeb.UserAuth

  def set(conn, %{"context" => context}) do
    conn = conn |> put_session(:last_context, context)

    conn = put_session(conn, :last_context, context)

    redirect(conn, to: UserAuth.signed_in_path(conn))
  end
end
