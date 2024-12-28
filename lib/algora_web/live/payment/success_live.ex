defmodule AlgoraWeb.Payment.SuccessLive do
  use AlgoraWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      if socket.assigns.current_user do
        socket
        |> put_flash(:info, "Your payment has been completed successfully!")
        |> push_navigate(to: ~p"/user/transactions")
      else
        socket
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden text-gray-600 dark:text-white bg-background">
      <div class="flex h-full flex-grow flex-col items-center justify-center overflow-hidden">
        <div class="mx-auto flex w-full max-w-2xl flex-col items-center justify-center">
          <div class="group/card relative h-full border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] flex flex-col items-center gap-4 rounded-lg px-10 py-16 text-center md:gap-4">
            <.icon name="tabler-circle-check" class="h-12 w-12 text-emerald-400" />
            <h1 class="text-2xl font-medium text-gray-800 dark:text-gray-100">
              Your payment has been completed successfully!
            </h1>
            <div class="text-base font-medium dark:text-gray-300">
              We'll send a receipt to your inbox.
            </div>
            <.link
              class="flex items-center gap-1 text-sm font-medium dark:text-emerald-400 hover:dark:text-emerald-300"
              navigate={~p"/"}
            >
              Back to dashboard
              <.icon name="tabler-arrow-right" class="mb-0.5 h-4 w-4 text-current" />
            </.link>
          </div>
          <div class="mt-8 text-center text-lg font-medium dark:text-gray-300">
            ❤️ Thank you for supporting open source software! ❤️
          </div>
        </div>
      </div>
    </div>
    """
  end
end
