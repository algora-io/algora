defmodule AlgoraWeb.Admin.Nav do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:contacts, [])
     |> assign(:admin_page?, true)
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
          %{href: "/admin#notes", tab: :notes, icon: "tabler-notes", label: "Notes"},
          %{href: "/admin#metrics", tab: :metrics, icon: "tabler-chart-dots", label: "Key Metrics"},
          %{
            href: "/admin#customers",
            tab: :customers,
            icon: "tabler-user-dollar",
            label: "Customers"
          },
          %{href: "/admin#funnel", tab: :funnel, icon: "tabler-filter", label: "Funnel"},
          %{href: "/admin/leaderboard", tab: :developers, icon: "tabler-user-code", label: "Developers"}
        ]
      },
      %{
        title: "User",
        items: [
          %{href: "/admin/dashboard", tab: :dashboard, icon: "tabler-dashboard", label: "Dashboard"},
          %{href: "/admin/dashboard/oban", tab: :oban, icon: "tabler-clock", label: "Job Queue"}
        ]
      }
    ]

    assign(socket, :nav, nav)
  end
end
