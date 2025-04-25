defmodule AlgoraWeb.Components.Banner do
  @moduledoc false
  use AlgoraWeb.Component
  use AlgoraWeb, :verified_routes

  import AlgoraWeb.CoreComponents

  alias AlgoraWeb.Constants

  def banner(assigns) do
    ~H"""
    <div class="group flex items-center gap-x-6 bg-emerald-600 px-6 py-1.5 sm:px-3.5 sm:before:flex-1 whitespace-nowrap">
      <p class="text-sm/6 text-foreground">
        <.link
          href={Constants.get(:github_repo_url)}
          rel="noopener"
          target="_blank"
          class="font-semibold"
        >
          <strong class="font-semibold">🎉 Algora is now open source!</strong><svg
            viewBox="0 0 2 2"
            class="mx-2 inline size-1 fill-current"
            aria-hidden="true"
          ><circle cx="1" cy="1" r="1" /></svg>Give us a star
          <.icon
            name="tabler-arrow-right"
            class="size-4 group-hover:translate-x-1.5 transition-transform"
          />
        </.link>
      </p>
      <div class="flex flex-1 justify-end">
        <%!-- <button type="button" class="-m-3 p-3 focus-visible:outline-offset-[-4px]">
          <span class="sr-only">Dismiss</span>
          <svg
            class="size-5 text-white"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
            data-slot="icon"
          >
            <path d="M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 1 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22Z" />
          </svg>
        </button> --%>
      </div>
    </div>
    """
  end
end
