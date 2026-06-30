defmodule AlgoraWeb.User.Nav do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.LiveView

  alias AlgoraWeb.User

  def on_mount(:default, params, _session, socket) do
    {:cont,
     socket
     |> assign(:screenshot?, not is_nil(params["screenshot"]))
     |> assign(:contacts, [])
     |> assign_nav_items()
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)}
  end

  def on_mount(:viewer, params, _session, socket) do
    {:cont,
     socket
     |> assign(:screenshot?, not is_nil(params["screenshot"]))
     |> assign(:contacts, [])
     |> assign_nav_items(:viewer)
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)}
  end

  defp handle_active_tab_params(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {AlgoraWeb.Community.DashboardLive, _} -> :dashboard
        {AlgoraWeb.User.DashboardLive, _} -> :dashboard
        {User.SettingsLive, _} -> :settings
        {User.TransactionsLive, _} -> :transactions
        {User.InstallationsLive, _} -> :installations
        {User.ProfileLive, _} -> :profile
        {AlgoraWeb.CommunityLive, _} -> :community
        {AlgoraWeb.BountiesLive, _} -> :bounties
        {AlgoraWeb.OrgsLive, _} -> :projects
        {_, _} -> nil
      end

    {:cont, assign(socket, :active_tab, active_tab)}
  end

  def assign_nav_items(socket, mode \\ :default)

  def assign_nav_items(%{assigns: %{current_user: nil}} = socket, _mode), do: socket

  def assign_nav_items(socket, :default) do
   nav = [
      %{
        title: nil,
        items: [
          %{label: "Dashboard", icon: "tabler-layout-dashboard", href: ~p"/home", tab: :dashboard},
          %{label: "Bounties", icon: "tabler-diamond", href: ~p"/bounties", tab: :bounties},
          %{label: "Projects", icon: "tabler-building", href: ~p"/projects", tab: :projects},
          %{label: "Transactions", icon: "tabler-receipt", href: ~p"/user/transactions", tab: :transactions},
          %{label: "Settings", icon: "tabler-settings", href: ~p"/user/settings", tab: :settings},
          %{label: "Installations", icon: "tabler-plug", href: ~p"/user/installations", tab: :installations}
        ]
      }
    ]

    assign(socket, :nav, nav)
  end

  def assign_nav_items(socket, :viewer) do
    assign(socket, :nav, [])
  end
end
