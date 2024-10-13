defmodule AlgoraWeb.Org.Nav do
  import Phoenix.LiveView
  use Phoenix.Component

  alias AlgoraWeb.Org

  def on_mount(:default, params, _session, socket) do
    org_handle = params["org_handle"]

    {:cont,
     socket
     |> assign(:org_handle, org_handle)
     |> assign(:nav, nav_items(org_handle))
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)}
  end

  defp handle_active_tab_params(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {Org.DashboardLive, _} -> :dashboard
        {Org.BountiesLive, _} -> :bounties
        {Org.ProjectsLive, _} -> :projects
        {Org.JobsLive, _} -> :jobs
        {Org.SettingsLive, _} -> :settings
        {Org.MembersLive, _} -> :members
        {_, _} -> nil
      end

    {:cont, socket |> assign(:active_tab, active_tab)}
  end

  def nav_items(org_handle) do
    [
      %{
        title: "Overview",
        items: [
          %{href: "/org/#{org_handle}", tab: :dashboard, icon: "tabler-home", label: "Dashboard"},
          %{
            href: "/org/#{org_handle}/bounties",
            tab: :bounties,
            icon: "tabler-diamond",
            label: "Bounties"
          },
          %{
            href: "/org/#{org_handle}/projects",
            tab: :projects,
            icon: "tabler-folder",
            label: "Projects"
          },
          %{href: "/org/#{org_handle}/jobs", tab: :jobs, icon: "tabler-briefcase", label: "Jobs"},
          %{
            href: "/org/#{org_handle}/community",
            tab: :community,
            icon: "tabler-world",
            label: "Community"
          }
        ]
      },
      %{
        title: "Settings",
        items: [
          %{
            href: "/org/#{org_handle}/settings",
            tab: :settings,
            icon: "tabler-settings",
            label: "General"
          },
          %{
            href: "/org/#{org_handle}/members",
            tab: :members,
            icon: "tabler-users",
            label: "Members"
          },
          %{
            href: "/org/#{org_handle}/github-bot",
            tab: :github_bot,
            icon: "tabler-robot",
            label: "GitHub Bot"
          },
          %{
            href: "/org/#{org_handle}/integrations",
            tab: :integrations,
            icon: "tabler-webhook",
            label: "Integrations"
          }
        ]
      },
      %{
        title: "Resources",
        items: [
          %{
            href: "/org/#{org_handle}/slash-commands",
            tab: :slash_commands,
            icon: "tabler-terminal",
            label: "Slash Commands"
          },
          %{
            href: "/org/#{org_handle}/documentation",
            tab: :documentation,
            icon: "tabler-script",
            label: "Documentation"
          },
          %{
            href: "/org/#{org_handle}/widgets",
            tab: :widgets,
            icon: "tabler-code",
            label: "Widgets"
          },
          %{href: "/org/#{org_handle}/sdk", tab: :sdk, icon: "tabler-sdk", label: "SDK"}
        ]
      }
    ]
  end
end
