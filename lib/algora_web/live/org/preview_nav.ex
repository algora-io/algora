defmodule AlgoraWeb.Org.PreviewNav do
  @moduledoc false
  use Phoenix.Component
  use AlgoraWeb, :verified_routes

  import Phoenix.LiveView

  alias Algora.Organizations

  def on_mount(:default, %{"repo_owner" => repo_owner, "repo_name" => repo_name}, _session, socket) do
    current_context = socket.assigns[:current_context]

    socket =
      socket
      |> assign(:new_bounty_form, to_form(%{"github_issue_url" => "", "amount" => ""}))
      |> assign(:current_org, current_context)
      |> assign(:current_user_role, :admin)
      |> assign(:nav, nav_items(repo_owner, repo_name))
      |> assign(:contacts, [])
      |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)

    if current_context && current_context.last_context == "repo/#{repo_owner}/#{repo_name}" do
      {:cont, socket}
    else
      preview_user =
        case socket.assigns[:preview_user] do
          nil ->
            case Organizations.init_preview(repo_owner, repo_name) do
              {:ok, %{user: user, org: _org}} -> user
              {:error, _reason} -> nil
            end

          user ->
            user
        end

      cond do
        is_nil(preview_user) ->
          {:cont, put_flash(socket, :error, "Failed to fetch repo")}

        # this is needed to avoid redirect loop that prevents og image from being fetched
        not connected?(socket) ->
          {:cont, socket}

        true ->
          token = AlgoraWeb.UserAuth.sign_preview_code(preview_user.id)
          preview_path = AlgoraWeb.UserAuth.preview_path(preview_user.id, token, ~p"/go/#{repo_owner}/#{repo_name}")
          {:halt, redirect(socket, to: preview_path)}
      end
    end
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
