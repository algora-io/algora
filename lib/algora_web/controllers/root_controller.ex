defmodule AlgoraWeb.RootController do
  use AlgoraWeb, :controller

  def index(%{assigns: %{current_user: nil}} = conn, _params) do
    # TODO: Redirect to user's country
    redirect(conn, to: ~p"/gr")
  end

  def index(conn, _params) do
    last_context = conn |> get_session(:last_context, nil)
    dbg(last_context)

    case last_context do
      nil -> redirect(conn, to: ~p"/dashboard")
      "personal" -> redirect(conn, to: ~p"/dashboard")
      org_handle -> redirect(conn, to: ~p"/org/#{org_handle}")
    end
  end
end
