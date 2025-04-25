defmodule AlgoraWeb.Components.Header do
  @moduledoc false
  use AlgoraWeb.Component
  use AlgoraWeb, :verified_routes

  import AlgoraWeb.CoreComponents

  defp nav_links do
    [
      %{name: "Bounties", path: ~p"/bounties"},
      %{name: "Testimonials", path: ~p"/testimonials"},
      %{name: "Crowdfund", path: ~p"/crowdfund"},
      %{name: "Docs", path: ~p"/docs"},
      %{name: "Pricing", path: ~p"/pricing"}
    ]
  end

  def header(assigns) do
    ~H"""
    <header class="absolute inset-x-0 top-0 z-50">
      <AlgoraWeb.Components.Banner.banner />

      <nav
        class="-mt-4 mx-auto flex max-w-7xl items-center justify-between p-6 lg:px-8"
        aria-label="Global"
      >
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
          <%= for link <- nav_links() do %>
            <.link
              navigate={link.path}
              class="text-sm/6 font-medium text-foreground/80 hover:text-foreground"
            >
              {link.name}
            </.link>
          <% end %>
        </div>

        <div class="hidden lg:flex lg:flex-1 lg:justify-end gap-2">
          <.link
            :if={Algora.Stargazer.count()}
            class="group w-fit outline-none items-center hidden lg:flex"
            target="_blank"
            rel="noopener"
            href={AlgoraWeb.Constants.get(:github_repo_url)}
          >
            <div class="rounded-[3px] hidden shrink-0 select-none items-center justify-center whitespace-nowrap bg-transparent text-center text-sm font-semibold transition duration-150 hover:bg-gray-850 disabled:opacity-50 group-focus:outline-none group-disabled:pointer-events-none group-disabled:opacity-75 lg:flex">
              <div class="flex w-full items-center justify-center gap-x-1">
                <.icon
                  name="github"
                  class="mr-0.5 h-5 shrink-0 justify-start text-foreground/80 group-hover:text-foreground transition"
                />
                <span class="hidden xl:block">Star</span>
                <span class="font-semibold text-foreground/80 group-hover:text-foreground">
                  {Algora.Stargazer.count()}
                </span>
              </div>
            </div>
          </.link>
          <.button
            navigate={~p"/auth/login"}
            variant="ghost"
            class="font-semibold text-foreground/80 hover:text-foreground"
          >
            Sign in
          </.button>
          <.button navigate={~p"/auth/signup"} variant="subtle" class="font-semibold">
            Sign up
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
                <%= for link <- nav_links() do %>
                  <.link
                    navigate={link.path}
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                  >
                    {link.name}
                  </.link>
                <% end %>
              </div>
              <div class="py-6 space-y-4">
                <.button
                  :if={Algora.Stargazer.count()}
                  class="group w-full flex items-center"
                  target="_blank"
                  rel="noopener"
                  variant="secondary"
                  href={AlgoraWeb.Constants.get(:github_repo_url)}
                >
                  <.icon
                    name="github"
                    class="mr-2 h-5 shrink-0 justify-start text-foreground/80 group-hover:text-foreground transition"
                  />
                  <span class="mr-1">Star</span>
                  <span class="font-semibold text-foreground/80 group-hover:text-foreground">
                    {Algora.Stargazer.count()}
                  </span>
                </.button>
                <.button navigate={~p"/auth/signup"} class="w-full">
                  Sign up
                </.button>
                <.button navigate={~p"/auth/login"} class="w-full" variant="secondary">
                  Sign in
                </.button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
    """
  end
end
