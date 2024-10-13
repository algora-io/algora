defmodule AlgoraWeb.Org.ProjectsLive do
  use AlgoraWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>Projects</div>
    """
  end
end
