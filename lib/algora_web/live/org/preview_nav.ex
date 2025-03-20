defmodule AlgoraWeb.Org.PreviewNav do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.LiveView

  alias Algora.Accounts.User
  alias Algora.Github.TokenPool
  alias Algora.Workspace

  def on_mount(:default, %{"repo_owner" => repo_owner, "repo_name" => repo_name}, _session, socket) do
    token = TokenPool.get_token()
    {:ok, _repo} = Workspace.ensure_repository(token, repo_owner, repo_name)
    {:ok, user} = Workspace.ensure_user(token, repo_owner)

    current_org = %User{
      id: Ecto.UUID.generate(),
      provider: "github",
      provider_login: repo_owner,
      name: user.name,
      handle: user.handle,
      avatar_url: user.avatar_url
    }

    {:cont,
     socket
     |> assign(:current_context, current_org)
     |> assign(:all_contexts, [current_org])
     |> assign(:new_bounty_form, to_form(%{"github_issue_url" => "", "amount" => ""}))
     |> assign(:current_org, current_org)
     |> assign(:current_user_role, :admin)
     |> assign(:nav, nav_items(repo_owner, repo_name))
     |> assign(:contacts, [])
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)}
  end

  defp handle_active_tab_params(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {AlgoraWeb.Org.DashboardLive, _} -> :dashboard
        {_, _} -> nil
      end

    {:cont, assign(socket, :active_tab, active_tab)}
  end

  def nav_items(repo_owner, repo_name) do
    [
      %{
        title: "Overview",
        items: [
          %{
            href: "/go/#{repo_owner}/#{repo_name}",
            tab: :dashboard,
            icon: "tabler-sparkles",
            label: "Dashboard"
          }
        ]
      }
    ]
  end
end
