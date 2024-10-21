defmodule AlgoraWeb.ContextController do
  use AlgoraWeb, :controller

  def set(conn, %{"context" => context}) do
    conn = conn |> put_session(:last_context, context)

    case context do
      "personal" -> redirect(conn, to: "/dashboard")
      org_handle -> redirect(conn, to: "/org/#{org_handle}")
    end
  end
end
