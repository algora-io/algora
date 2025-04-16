defmodule AlgoraWeb.Org.PreviewNav do
  @moduledoc false
  use Phoenix.Component
  use AlgoraWeb, :verified_routes

  import Phoenix.LiveView

  alias Algora.Accounts
  alias Algora.Organizations

  require Logger

  def on_mount(:default, %{"repo_owner" => repo_owner, "repo_name" => repo_name, "token" => token}, _session, socket) do
    case Phoenix.Token.decrypt(AlgoraWeb.Endpoint, Algora.config([:local_store, :salt]), token) do
      {:ok, %{user_id: user_id, org_id: org_id}} ->
        user = Accounts.get_user!(user_id)
        org = Accounts.get_user!(org_id)

        {:cont,
         socket
         |> assign(:new_bounty_form, to_form(%{"github_issue_url" => "", "amount" => ""}))
         |> assign(:current_org, org)
         |> assign(:current_user, user)
         |> assign(:current_context, org)
         |> assign(:all_contexts, [org])
         |> assign(:current_user_role, :admin)
         |> assign(:nav, nav_items(repo_owner, repo_name))
         |> assign(:contacts, [])
         |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)}

      {:error, reason} ->
        Logger.error("Failed to restore preview state for #{repo_owner}/#{repo_name}: #{inspect(reason)}")
        raise AlgoraWeb.NotFoundError
    end
  end

  def on_mount(:default, %{"repo_owner" => repo_owner, "repo_name" => repo_name} = params, _session, socket) do
    current_context = socket.assigns[:current_context]

    socket =
      socket
      |> assign(:new_bounty_form, to_form(%{"github_issue_url" => "", "amount" => ""}))
      |> assign(:current_org, current_context)
      |> assign(:current_user_role, :admin)
      |> assign(:nav, nav_items(repo_owner, repo_name))
      |> assign(:contacts, [])
      |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)

    # checking if the socket is connected to avoid redirect loop that prevents og image from being fetched
    if (current_context && current_context.last_context == "repo/#{repo_owner}/#{repo_name}") ||
         (not connected?(socket) && is_nil(params["screenshot"])) do
      {:cont, socket}
    else
      preview_user =
        case socket.assigns[:preview_user] do
          nil ->
            if email = params["email"] do
              Algora.Admin.alert("New preview for #{repo_owner}/#{repo_name} by #{email}", :info)
            else
              Algora.Admin.alert("New preview for #{repo_owner}/#{repo_name}", :debug)
            end

            case Organizations.init_preview(repo_owner, repo_name) do
              {:ok, %{user: user, org: _org}} -> user
              {:error, _reason} -> nil
            end

          user ->
            user
        end

      if is_nil(preview_user) do
        {:cont, put_flash(socket, :error, "Failed to fetch repo")}
      else
        token = AlgoraWeb.UserAuth.sign_preview_code(preview_user.id)

        search_params =
          Map.reject(%{email: params["email"], screenshot: params["screenshot"]}, fn {_k, v} -> is_nil(v) end)

        return_to =
          if search_params == %{},
            do: ~p"/go/#{repo_owner}/#{repo_name}",
            else: ~p"/go/#{repo_owner}/#{repo_name}?#{search_params}"

        preview_path = AlgoraWeb.UserAuth.preview_path(preview_user.id, token, return_to)

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
