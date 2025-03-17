defmodule AlgoraWeb.User.Nav do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.LiveView

  alias AlgoraWeb.User

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:admin_page?, false)
     |> assign(:contacts, [])
     |> assign_nav_items()
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

  def assign_nav_items(%{assigns: %{current_user: nil}} = socket) do
    socket
  end

  def assign_nav_items(socket) do
    nav = [
      %{
        title: "Main",
        items: [
          %{href: "/", tab: :dashboard, icon: "tabler-home", label: "Dashboard"},
          %{href: "/@/#{socket.assigns.current_user.handle}", tab: :profile, icon: "tabler-user", label: "Profile"},
          %{href: "/bounties", tab: :bounties, icon: "tabler-diamond", label: "Bounties"},
          %{href: "/projects", tab: :projects, icon: "tabler-rocket", label: "Projects"},
          %{href: "/community", tab: :community, icon: "tabler-users", label: "Community"},
          %{href: "/user/transactions", tab: :transactions, icon: "tabler-wallet", label: "Transactions"},
          %{
            href: "https://tv.algora.io",
            tab: :tv,
            icon: "tabler-device-tv",
            label: "Algora TV",
            target: "_blank"
          },
          %{href: "/user/settings", tab: :settings, icon: "tabler-settings", label: "Settings"}
        ]
      }
    ]

    assign(socket, :nav, nav)
  end
end
