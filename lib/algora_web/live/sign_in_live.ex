defmodule AlgoraWeb.SignInLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-[calc(100vh-64px)] flex flex-col justify-center">
      <div class="mb-[64px] mx-auto max-w-3xl p-12 sm:mx-auto sm:w-full sm:max-w-sm sm:p-24">
        <h2 class="text-center text-3xl font-extrabold text-gray-50">
          Algora Console
        </h2>
        <.link
          href={@authorize_url}
          rel="noopener"
          class="mt-8 flex w-full justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2"
        >
          Sign in with GitHub
        </.link>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    authorize_url =
      case params["return_to"] do
        nil -> Algora.Github.authorize_url()
        return_to -> Algora.Github.authorize_url(%{return_to: return_to})
      end

    {:ok, assign(socket, authorize_url: authorize_url)}
  end
end
