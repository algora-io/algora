defmodule AlgoraWeb.User.DashboardLive do
  use AlgoraWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="w-full max-w-3xl space-y-6 p-4 md:p-16">
      <div class="mb-4 flex items-center justify-between">
        <h2 class="text-2xl font-bold dark:text-white font-display">Welcome to Algora</h2>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
