defmodule AlgoraWeb.User.InstallationsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Github
  alias Algora.Workspace

  def render(assigns) do
    ~H"""
    <div class="w-full max-w-3xl space-y-6 p-4 md:p-16">
      <div class="mb-4 flex items-center justify-between">
        <h2 class="text-2xl font-bold dark:text-white">Manage your installations</h2>
      </div>
      <ul class="space-y-6">
        <%= for installation <- @installations do %>
          <li>
            <div class="group/card bg-white/[2%] from-white/[2%] via-white/[2%] to-white/[2%] relative h-full rounded-xl border border-white/10 bg-gradient-to-br p-8 md:gap-8">
              <div class="relative divide-y-2 divide-gray-700">
                <div class="flex items-center gap-4">
                  <div class="relative h-10 w-10">
                    <img
                      alt={installation.provider_user.provider_login}
                      class="rounded-lg"
                      src={installation.provider_user.avatar_url}
                    />
                  </div>
                  <div>
                    <div class="text-xl font-semibold tracking-tight text-gray-100">
                      {installation.provider_user.provider_login}
                    </div>
                    <div>
                      <div class="text-sm text-gray-300">
                        Installed on
                        <span class="font-semibold text-gray-200">
                          {installation.repository_selection} repositories
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="mt-8 pt-8">
                  <label
                    class="flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300 "
                    id="headlessui-listbox-label-:r0:"
                    data-headlessui-state=""
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                      class="h-4 w-4"
                    ><path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244"
                      ></path></svg>Linked to
                  </label>
                  <div class="relative mt-2">
                    <button
                      class="relative w-full cursor-pointer rounded-md border border-gray-300 bg-white py-2 pr-10 pl-3 text-left shadow-sm focus:border-gray-500 focus:outline-none focus:ring-1 focus:ring-gray-500 sm:text-sm dark:border-gray-500 dark:bg-gray-700 dark:focus:border-gray-500 dark:focus:ring-gray-500"
                      id="headlessui-listbox-button-:r1:"
                      type="button"
                      aria-haspopup="listbox"
                      aria-expanded="false"
                      data-headlessui-state=""
                      aria-labelledby="headlessui-listbox-label-:r0: headlessui-listbox-button-:r1:"
                    >
                      <span class="block truncate dark:text-white">
                        {(installation.connected_user && installation.connected_user.handle) ||
                          "None"}
                      </span>
                      <span class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 20 20"
                          fill="currentColor"
                          aria-hidden="true"
                          class="h-5 w-5 text-gray-400 dark:text-gray-300"
                        >
                          <path
                            fill-rule="evenodd"
                            d="M10 3a.75.75 0 01.55.24l3.25 3.5a.75.75 0 11-1.1 1.02L10 4.852 7.3 7.76a.75.75 0 01-1.1-1.02l3.25-3.5A.75.75 0 0110 3zm-3.76 9.2a.75.75 0 011.06.04l2.7 2.908 2.7-2.908a.75.75 0 111.1 1.02l-3.25 3.5a.75.75 0 01-1.1 0l-3.25-3.5a.75.75 0 01.04-1.06z"
                            clip-rule="evenodd"
                          >
                          </path>
                        </svg>
                      </span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </li>
        <% end %>
      </ul>
      <.link
        class="relative block w-full rounded-lg border-2 border-dashed border-gray-600 p-8 text-center hover:border-gray-500"
        rel="noopener"
        href={Github.install_url_new()}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          aria-hidden="true"
          class="mx-auto h-12 w-12 text-gray-400"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M21 7.5l-9-5.25L3 7.5m18 0l-9 5.25m9-5.25v9l-9 5.25M3 7.5l9 5.25M3 7.5v9l9 5.25m0-9v9"
          >
          </path>
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-gray-200">
          Manage installations
        </h3>
      </.link>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    installations = Workspace.list_installations_by(owner_id: socket.assigns.current_user.id)
    {:ok, assign(socket, :installations, installations)}
  end
end
