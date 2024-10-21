defmodule AlgoraWeb.RootController do
  use AlgoraWeb, :controller
  alias AlgoraWeb.UserAuth

  def index(%{assigns: %{current_user: nil}} = conn, _params) do
    # TODO: Redirect to user's country
    redirect(conn, to: ~p"/gr")
  end

  def index(conn, _params) do
    redirect(conn, to: UserAuth.signed_in_path(conn))
  end
end
