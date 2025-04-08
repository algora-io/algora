defmodule AlgoraWeb.OrgAuth do
  @moduledoc false
  import Phoenix.LiveView

  alias Algora.Organizations

  def on_mount(:ensure_admin, params, session, socket) do
    ensure_role([:admin], params, session, socket)
  end

  def on_mount(:ensure_mod, params, session, socket) do
    ensure_role([:mod, :admin], params, session, socket)
  end

  def get_user_role(nil, _org), do: :none

  def get_user_role(user, _org) when user.is_admin, do: :admin

  def get_user_role(user, org) when org.id == user.id, do: :admin

  def get_user_role(user, org) do
    case Organizations.fetch_member(org.id, user.id) do
      {:ok, member} -> member.role
      _ -> :none
    end
  end

  defp ensure_role(allowed_roles, _params, _session, socket) do
    %{current_org: current_org, current_user: current_user} = socket.assigns

    if get_user_role(current_user, current_org) in allowed_roles do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/#{current_org.handle}")}
    end
  end
end
