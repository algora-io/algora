defmodule AlgoraWeb.Admin.Nav do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.LiveView

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
          %{href: "/admin/analytics#notes", tab: :notes, icon: "tabler-notebook", label: "Notes"},
          %{
            href: "/admin/analytics#company-analytics",
            tab: :company_analytics,
            icon: "tabler-chart-area-line",
            label: "Company Analytics"
          },
          %{href: "/admin/analytics#key-metrics", tab: :key_metrics, icon: "tabler-chart-dots", label: "Key Metrics"},
          %{
            href: "/admin/analytics#company-details",
            tab: :company_details,
            icon: "tabler-building",
            label: "Company Details"
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
