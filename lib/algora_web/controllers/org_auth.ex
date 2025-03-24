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

  defp ensure_role(allowed_roles, _params, _session, socket) do
    %{current_org: current_org, current_user: current_user} = socket.assigns

    user_role =
      if current_org.id == current_user.id do
        {:ok, :admin}
      else
        with {:ok, member} <- Organizations.fetch_member(current_org.id, current_user.id) do
          {:ok, member.role}
        end
      end

    with {:ok, role} <- user_role,
         true <- role in allowed_roles do
      {:cont, socket}
    else
      _ -> {:halt, redirect(socket, to: "/org/#{current_org.handle}")}
    end
  end
end
