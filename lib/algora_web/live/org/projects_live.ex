defmodule AlgoraWeb.Org.ProjectsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  on_mount AlgoraWeb.Org.BountyHook

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>Projects</div>
    """
  end
end
