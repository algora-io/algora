defmodule AlgoraWeb.SignInLive do
  use AlgoraWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-[calc(100vh-64px)] flex flex-col justify-center">
      <div class="sm:mx-auto sm:w-full sm:max-w-sm max-w-3xl mx-auto mb-[64px] p-12 sm:p-24">
        <h2 class="text-center text-3xl font-extrabold text-gray-50">
          Algora Console
        </h2>
        <.link
          href={Algora.Github.authorize_url()}
          rel="noopener"
          class="mt-8 w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
        >
          Sign in with GitHub
        </.link>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
