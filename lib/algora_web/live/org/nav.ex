defmodule AlgoraWeb.Org.Nav do
  import Phoenix.LiveView
  use Phoenix.Component

  alias Algora.Organizations

  def on_mount(:default, %{"org_handle" => org_handle}, _session, socket) do
    current_org = Organizations.get_org_by(handle: org_handle)
    members = Organizations.list_org_members(current_org)
    contractors = Organizations.list_org_contractors(current_org)

    online_users =
      (contractors ++ members)
      |> Enum.uniq_by(& &1.id)
      |> Enum.reject(&(&1.id == socket.assigns.current_user.id))
      |> Enum.map(fn user ->
        %{
          id: user.id,
          name: user.name || user.handle,
          handle: user.handle,
          avatar_url: user.avatar_url
        }
      end)

    {:cont,
     socket
     |> assign(:new_bounty_form, to_form(%{"github_issue_url" => "", "amount" => ""}))
     |> assign(:current_org, current_org)
     |> assign(:nav, nav_items(current_org.handle))
     |> assign(:online_users, online_users)
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)}
  end

  defp handle_active_tab_params(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {AlgoraWeb.Org.DashboardLive, _} -> :dashboard
        {AlgoraWeb.Org.BountiesLive, _} -> :bounties
        {AlgoraWeb.Org.ProjectsLive, _} -> :projects
        {AlgoraWeb.Project.ViewLive, _} -> :projects
        {AlgoraWeb.Org.JobsLive, _} -> :jobs
        {AlgoraWeb.Org.SettingsLive, _} -> :settings
        {AlgoraWeb.Org.MembersLive, _} -> :members
        {_, _} -> nil
      end

    {:cont, socket |> assign(:active_tab, active_tab)}
  end

  def nav_items(org_handle) do
    [
      %{
        title: "Overview",
        items: [
          %{
            href: "/org/#{org_handle}",
            tab: :dashboard,
            icon: "tabler-flower",
            label: "Dashboard"
          },
          %{
            href: "/org/#{org_handle}/bounties",
            tab: :bounties,
            icon: "tabler-diamond",
            label: "Bounties"
          },
          %{href: "/org/#{org_handle}/jobs", tab: :jobs, icon: "tabler-briefcase", label: "Jobs"},
          %{
            href: "/org/#{org_handle}/team",
            tab: :team,
            icon: "tabler-users",
            label: "Team"
          },
          %{
            href: "/org/#{org_handle}/analytics",
            tab: :analytics,
            icon: "tabler-chart-bar",
            label: "Analytics"
          },
          %{
            href: "/org/#{org_handle}/settings",
            tab: :settings,
            icon: "tabler-settings",
            label: "Settings"
          }
        ]
      }
    ]
  end
end
