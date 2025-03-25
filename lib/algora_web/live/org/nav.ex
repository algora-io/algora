defmodule AlgoraWeb.Org.Nav do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.LiveView

  alias Algora.Organizations
  alias AlgoraWeb.OrgAuth

  def on_mount(:default, %{"org_handle" => org_handle} = params, _session, socket) do
    current_user = socket.assigns[:current_user]
    current_org = Organizations.get_org_by(handle: org_handle)
    current_user_role = OrgAuth.get_user_role(current_user, current_org)

    # TODO: restore once chat is implemented
    contacts = []

    # members = Organizations.list_org_members(current_org) |> Enum.map(& &1.user)
    # contractors = Organizations.list_org_contractors(current_org)
    # contacts =
    #   (contractors ++ members)
    #   |> Enum.uniq_by(& &1.id)
    #   |> Enum.reject(&(&1.id == socket.assigns.current_user.id))
    #   |> Enum.map(fn user ->
    #     %{
    #       id: user.id,
    #       name: user.name || user.handle,
    #       handle: user.handle,
    #       avatar_url: user.avatar_url,
    #       type: :individual
    #     }
    #   end)

    {:cont,
     socket
     |> assign(:screenshot?, not is_nil(params["screenshot"]))
     |> assign(:new_bounty_form, to_form(%{"github_issue_url" => "", "amount" => ""}))
     |> assign(:current_org, current_org)
     |> assign(:current_user_role, current_user_role)
     |> assign(:nav, nav_items(current_org.handle, current_user_role))
     |> assign(:contacts, contacts)
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)}
  end

  defp handle_active_tab_params(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {AlgoraWeb.Org.DashboardLive, _} -> :dashboard
        {AlgoraWeb.Org.HomeLive, _} -> :home
        {AlgoraWeb.Org.BountiesLive, _} -> :bounties
        {AlgoraWeb.Org.ProjectsLive, _} -> :projects
        {AlgoraWeb.Project.ViewLive, _} -> :projects
        {AlgoraWeb.Org.SettingsLive, _} -> :settings
        {AlgoraWeb.Org.MembersLive, _} -> :members
        {_, _} -> nil
      end

    {:cont, assign(socket, :active_tab, active_tab)}
  end

  def nav_items(org_handle, current_user_role) do
    [
      %{
        title: "Overview",
        items: build_nav_items(org_handle, current_user_role)
      }
    ]
  end

  defp build_nav_items(org_handle, current_user_role) do
    Enum.filter(
      [
        %{
          href: "/org/#{org_handle}",
          tab: :dashboard,
          icon: "tabler-sparkles",
          label: "Dashboard",
          roles: [:admin, :mod]
        },
        %{
          href: "/org/#{org_handle}/home",
          tab: :home,
          icon: "tabler-home",
          label: "Home",
          roles: [:admin, :mod, :expert, :none]
        },
        %{
          href: "/org/#{org_handle}/bounties",
          tab: :bounties,
          icon: "tabler-diamond",
          label: "Bounties",
          roles: [:admin, :mod, :expert, :none]
        },
        %{
          href: "/org/#{org_handle}/leaderboard",
          tab: :leaderboard,
          icon: "tabler-trophy",
          label: "Leaderboard",
          roles: [:admin, :mod, :expert, :none]
        },
        %{
          href: "/org/#{org_handle}/team",
          tab: :team,
          icon: "tabler-users",
          label: "Team",
          roles: [:admin, :mod, :expert, :none]
        },
        %{
          href: "/org/#{org_handle}/transactions",
          tab: :transactions,
          icon: "tabler-credit-card",
          label: "Transactions",
          roles: [:admin]
        },
        %{
          href: "/org/#{org_handle}/settings",
          tab: :settings,
          icon: "tabler-settings",
          label: "Settings",
          roles: [:admin]
        }
      ],
      fn item -> current_user_role in item[:roles] end
    )
  end
end
