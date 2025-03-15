defmodule AlgoraWeb.User.Nav do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.LiveView

  alias AlgoraWeb.User

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
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
      },
      %{
        title: "User",
        items: [
          %{
            href: "/user/installations",
            tab: :installations,
            icon: "tabler-apps",
            label: "Installations"
          },
          %{
            href: "/user/payouts",
            tab: :earnings,
            icon: "tabler-currency-dollar",
            label: "Earnings"
          }
        ]
      },
      %{
        title: "Resources",
        items: [
          %{href: "/onboarding", tab: :onboarding, icon: "tabler-rocket", label: "Get started"},
          %{href: "https://docs.algora.io", icon: "tabler-book", label: "Documentation"},
          %{href: "https://github.com/algora-io/sdk", icon: "tabler-code", label: "Algora SDK"}
        ]
      },
      %{
        title: "Admin",
        items: [
          %{href: "/admin", tab: :admin, icon: "tabler-adjustments", label: "Admin"},
          %{href: "/auth/logout", icon: "tabler-logout", label: "Logout"}
        ]
      },
      %{
        title: "Community",
        items: [
          %{
            href: "https://docs.algora.io/contact",
            icon: "tabler-send",
            label: "Talk to founders"
          },
          %{href: "https://algora.io/discord", icon: "tabler-brand-discord", label: "Discord"},
          %{href: "https://twitter.com/algoraio", icon: "tabler-brand-x", label: "Twitter"},
          %{
            href: "https://youtube.com/@algora-io",
            icon: "tabler-brand-youtube",
            label: "YouTube"
          }
        ]
      }
    ]

    assign(socket, :nav, nav)
  end
end
