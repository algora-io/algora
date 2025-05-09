defmodule AlgoraWeb.RootController do
  use AlgoraWeb, :controller

  alias AlgoraWeb.Analytics
  alias AlgoraWeb.UserAuth

  def index(%{assigns: %{current_user: nil}} = conn, _params) do
    redirect(conn, to: "/#{Analytics.get_current_country(conn)}")
  end

  def index(conn, _params) do
    redirect(conn, to: UserAuth.signed_in_path(conn))
  end
end
