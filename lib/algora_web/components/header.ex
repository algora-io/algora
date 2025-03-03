defmodule AlgoraWeb.Components.Header do
  @moduledoc false
  use AlgoraWeb.Component
  use AlgoraWeb, :verified_routes

  import AlgoraWeb.CoreComponents

  def header(assigns) do
    ~H"""
    <header class="absolute inset-x-0 top-0 z-50">
      <nav class="mx-auto flex max-w-7xl items-center justify-between p-6 lg:px-8" aria-label="Global">
        <div class="flex lg:flex-1">
          <.wordmark class="h-8 w-auto text-foreground" />
        </div>
        <!-- Mobile menu button -->
        <div class="flex lg:hidden">
          <button
            type="button"
            class="rounded-md p-2.5 text-muted-foreground hover:text-foreground"
            phx-click={JS.show(to: "#mobile-menu")}
          >
            <span class="sr-only">Open main menu</span>
            <.icon name="tabler-menu" class="h-6 w-6" />
          </button>
        </div>
        <!-- Desktop nav -->
        <div class="hidden lg:flex lg:gap-x-12">
          <.link
            href={AlgoraWeb.Constants.get(:docs_url)}
            class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground"
          >
            Docs
          </.link>
          <.link
            href={AlgoraWeb.Constants.get(:blog_url)}
            class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground"
          >
            Blog
          </.link>
          <.link
            navigate={~p"/pricing"}
            class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground"
          >
            Pricing
          </.link>
          <.link
            href={AlgoraWeb.Constants.get(:github_url)}
            class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground"
          >
            GitHub
          </.link>
        </div>

        <div class="hidden lg:flex lg:flex-1 lg:justify-end">
          <.button navigate={~p"/auth/login"} variant="subtle">
            Sign in
          </.button>
        </div>
      </nav>
      <!-- Mobile menu -->
      <div id="mobile-menu" class="lg:hidden hidden" role="dialog" aria-modal="true">
        <div class="fixed inset-0 z-50"></div>
        <div class="fixed inset-y-0 right-0 z-50 w-full overflow-y-auto bg-background px-6 py-6 sm:max-w-sm sm:ring-1 sm:ring-border">
          <!-- Mobile menu content -->
          <div class="flex items-center justify-between">
            <.wordmark class="h-8 w-auto text-foreground" />
            <button
              type="button"
              class="rounded-md p-2.5 text-muted-foreground hover:text-foreground"
              phx-click={JS.hide(to: "#mobile-menu")}
            >
              <span class="sr-only">Close menu</span>
              <.icon name="tabler-x" class="h-6 w-6" />
            </button>
          </div>

          <div class="mt-6 flow-root">
            <div class="-my-6 divide-y divide-border">
              <div class="space-y-2 py-6">
                <.link
                  href={AlgoraWeb.Constants.get(:docs_url)}
                  class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                >
                  Docs
                </.link>
                <.link
                  href={AlgoraWeb.Constants.get(:blog_url)}
                  class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                >
                  Blog
                </.link>
                <.link
                  navigate={~p"/pricing"}
                  class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                >
                  Pricing
                </.link>
                <.link
                  href={AlgoraWeb.Constants.get(:github_url)}
                  class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                >
                  GitHub
                </.link>
              </div>
              <div class="py-6">
                <.link
                  navigate={~p"/auth/login"}
                  class="-mx-3 block rounded-lg px-3 py-2.5 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                >
                  Sign in
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
    """
  end
end
