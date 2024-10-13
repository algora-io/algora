defmodule AlgoraWeb.Org.DashboardLive do
  use AlgoraWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>Dashboard</div>
    """
  end
end
