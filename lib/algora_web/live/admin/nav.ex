defmodule AlgoraWeb.Admin.Nav do
  @moduledoc false
  use Phoenix.Component
  use AlgoraWeb, :verified_routes

  import Phoenix.LiveView

  alias Algora.Chat

  def on_mount(:default, _params, _session, socket) do
    threads =
      socket.assigns.current_user.id
      |> Chat.list_threads()
      |> Enum.flat_map(fn thread ->
        case Enum.find(thread.participants, fn p -> !p.user.is_admin end) do
          nil -> []
          contact -> [%{thread: thread, contact: contact.user, path: ~p"/admin/chat/#{thread.id}"}]
        end
      end)

    {:cont,
     socket
     |> assign(:threads, threads)
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
          %{href: "/admin#traffic", tab: :traffic, icon: "tabler-traffic-lights", label: "Traffic"},
          %{href: "/admin/leaderboard", tab: :developers, icon: "tabler-user-code", label: "Developers"},
          %{href: "/admin/campaign", tab: :campaigns, icon: "tabler-mail", label: "Campaign"}
        ]
      },
      %{
        title: "User",
        items: [
          %{href: "/admin/dashboard/metrics?nav=algora", tab: :dashboard, icon: "tabler-dashboard", label: "Dashboard"},
          %{href: "/admin/oban", tab: :oban, icon: "tabler-clock", label: "Job Queue"}
        ]
      }
    ]

    assign(socket, :nav, nav)
  end
end
