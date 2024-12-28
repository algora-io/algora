defmodule AlgoraWeb.Payment.CanceledLive do
  use AlgoraWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden text-gray-600 dark:text-white bg-background">
      <div class="flex h-full flex-grow flex-col items-center justify-center overflow-hidden">
        <div class="mx-auto flex w-full max-w-2xl flex-col items-center justify-center">
          <div class="group/card relative h-full border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] flex flex-col items-center gap-4 rounded-lg px-10 py-16 text-center md:gap-4">
            <div
              class="absolute inset-0 opacity-100 transition-opacity duration-1000 ease-in-out pointer-events-none"
              aria-hidden="true"
            >
              <canvas width="753" height="375" style="width: 603px; height: 300px;"></canvas>
            </div>
            <.icon name="tabler-circle-x" class="h-12 w-12 text-amber-400" />
            <h1 class="text-2xl font-medium text-gray-800 dark:text-gray-100">
              Your payment has been canceled.
            </h1>
            <.link
              class="flex items-center gap-1 text-sm font-medium dark:text-amber-400 hover:dark:text-amber-300"
              navigate={~p"/"}
            >
              Back to dashboard
              <.icon name="tabler-arrow-right" class="mb-0.5 h-4 w-4 text-current" />
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
