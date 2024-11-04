defmodule AlgoraWeb.User.Nav do
  import Phoenix.LiveView
  use Phoenix.Component

  alias Algora.Accounts
  alias AlgoraWeb.User

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:nav, nav_items())
     |> assign(:online_orgs, Accounts.list_orgs(limit: 10))
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)}
  end

  defp handle_active_tab_params(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {User.SettingsLive, _} -> :settings
        {User.InstallationsLive, _} -> :installations
        {_, _} -> nil
      end

    {:cont, socket |> assign(:active_tab, active_tab)}
  end

  def nav_items() do
    [
      %{
        title: "Main Navigation",
        items: [
          %{href: "/events", tab: :activity, icon: "tabler-activity", label: "Activity"},
          %{href: "/dashboard/orgs", tab: :projects, icon: "tabler-rocket", label: "Projects"},
          %{
            href: "/bounties/new",
            tab: :bounties,
            icon: "tabler-diamond",
            label: "Community bounties"
          },
          %{
            href: "https://tv.algora.io",
            tab: :media,
            icon: "tabler-device-tv",
            label: "Media center"
          }
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
          %{href: "/user/settings", tab: :settings, icon: "tabler-settings", label: "Settings"},
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
  end
end
