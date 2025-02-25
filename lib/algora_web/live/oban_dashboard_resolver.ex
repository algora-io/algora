defmodule AlgoraWeb.ObanDashboardResolver do
  @behaviour Oban.Web.Resolver

  @impl true
  def resolve_user(conn) do
    conn.assigns.current_user
  end

  @impl true
  def resolve_access(user) do
    case user do
      %{is_admin: true} -> :all
      _ -> {:forbidden, "/auth/login"}
    end
  end
end
