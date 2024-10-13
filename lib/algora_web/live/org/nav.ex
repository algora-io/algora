defmodule AlgoraWeb.Org.Nav do
  import Phoenix.LiveView
  use Phoenix.Component

  alias AlgoraWeb.Org

  def on_mount(:default, params, _session, socket) do
    {:cont,
     socket
     |> assign(:org_handle, params["org_handle"])
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)}
  end

  defp handle_active_tab_params(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {Org.DashboardLive, _} ->
          :dashboard

        {Org.BountiesLive, _} ->
          :bounties

        {Org.ProjectsLive, _} ->
          :projects

        {Org.JobsLive, _} ->
          :jobs

        {_, _} ->
          nil
      end

    {:cont, socket |> assign(:active_tab, active_tab)}
  end
end
