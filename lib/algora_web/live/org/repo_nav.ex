defmodule AlgoraWeb.Org.RepoNav do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.LiveView

  alias Algora.Organizations
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.OrgAuth

  def on_mount(:default, %{"repo_owner" => repo_owner} = params, _session, socket) do
    current_user = socket.assigns[:current_user]
    current_org = Organizations.get_org_by(provider_login: repo_owner, provider: "github")
    current_user_role = OrgAuth.get_user_role(current_user, current_org)

    {:cont,
     socket
     |> assign(:screenshot?, not is_nil(params["screenshot"]))
     |> assign(:main_bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
     |> assign(:main_bounty_form_open?, false)
     |> assign(:current_org, current_org)
     |> assign(:current_user_role, current_user_role)
     |> assign(:nav, nav_items(current_org.handle, current_user_role))
     |> assign(:contacts, [])
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)
     |> attach_hook(:form_toggle, :handle_event, &handle_form_toggle_event/3)}
  end

  # TODO: handle submit
  # TODO: handle validate

  defp handle_form_toggle_event("open_main_bounty_form", _params, socket) do
    {:cont, assign(socket, :main_bounty_form_open?, true)}
  end

  defp handle_form_toggle_event("close_main_bounty_form", _params, socket) do
    {:cont, assign(socket, :main_bounty_form_open?, false)}
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
