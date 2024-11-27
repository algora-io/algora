defmodule AlgoraWeb.HomeLive do
  use AlgoraWeb, :live_view
  alias Algora.Users
  alias Algora.Money

  @impl true
  def mount(%{"country_code" => country_code}, _session, socket) do
    Gettext.put_locale(AlgoraWeb.Gettext, Algora.Util.locale_from_country_code(country_code))

    {:ok,
     socket
     |> assign(:featured_devs, Users.list_featured_devs())
     |> assign(:featured_orgs, list_featured_orgs())
     |> assign(:stats, fetch_stats())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gradient-to-br from-primary/5 to-muted/20">
      <header class="absolute inset-x-0 top-0 z-50">
        <nav
          class="mx-auto flex max-w-7xl items-center justify-between p-6 lg:px-8"
          aria-label="Global"
        >
          <div class="flex lg:flex-1">
            <.wordmark class="text-foreground h-8 w-auto" />
          </div>
          <!-- Mobile menu button -->
          <div class="flex lg:hidden">
            <button type="button" class="rounded-md p-2.5 text-muted-foreground hover:text-foreground">
              <span class="sr-only">Open main menu</span>
              <.icon name="tabler-menu" class="h-6 w-6" />
            </button>
          </div>
          <!-- Desktop nav -->
          <div class="hidden lg:flex lg:gap-x-12">
            <a href="#" class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground">
              Companies
            </a>
            <a href="#" class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground">
              Developers
            </a>
            <a href="#" class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground">
              Open source
            </a>
          </div>

          <div class="hidden lg:flex lg:flex-1 lg:justify-end">
            <.link
              navigate={~p"/auth/login"}
              class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground"
            >
              Log in <span aria-hidden="true">&rarr;</span>
            </.link>
          </div>
        </nav>
        <!-- Mobile menu -->
        <div class="lg:hidden" role="dialog" aria-modal="true">
          <div class="fixed inset-0 z-50"></div>
          <div class="fixed inset-y-0 right-0 z-50 w-full overflow-y-auto bg-background px-6 py-6 sm:max-w-sm sm:ring-1 sm:ring-border">
            <!-- Mobile menu content -->
            <div class="flex items-center justify-between">
              <.wordmark class="text-foreground h-8 w-auto" />
              <button
                type="button"
                class="rounded-md p-2.5 text-muted-foreground hover:text-foreground"
              >
                <span class="sr-only">Close menu</span>
                <.icon name="tabler-x" class="h-6 w-6" />
              </button>
            </div>

            <div class="mt-6 flow-root">
              <div class="-my-6 divide-y divide-border">
                <div class="space-y-2 py-6">
                  <a
                    href="#"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                  >
                    Product
                  </a>
                  <a
                    href="#"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                  >
                    Features
                  </a>
                  <a
                    href="#"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                  >
                    Marketplace
                  </a>
                  <a
                    href="#"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                  >
                    Company
                  </a>
                </div>
                <div class="py-6">
                  <.link
                    navigate={~p"/auth/login"}
                    class="-mx-3 block rounded-lg px-3 py-2.5 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                  >
                    Log in
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </header>

      <main>
        <div class="relative isolate">
          <!-- Background pattern -->
          <div
            class="absolute inset-x-0 -top-40 -z-10 transform overflow-hidden blur-3xl sm:-top-80"
            aria-hidden="true"
          >
            <div
              class="relative left-[calc(50%-11rem)] aspect-[1155/678] w-[36.125rem] -translate-x-1/2 rotate-[30deg] bg-gradient-to-tr from-primary to-secondary opacity-20 sm:left-[calc(50%-30rem)] sm:w-[72.1875rem]"
              style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
            >
            </div>
          </div>

          <div class="absolute inset-x-0 -z-10 h-screen w-full stroke-border [mask-image:radial-gradient(32rem_32rem_at_center,white,transparent)]">
            <defs>
              <pattern
                id="grid-pattern"
                width="200"
                height="200"
                x="50%"
                y="-1"
                patternUnits="userSpaceOnUse"
              >
                <path d="M.5 200V.5H200" fill="none" />
              </pattern>
            </defs>
            <rect
              width="100%"
              height="100%"
              stroke-width="0"
              fill="url(#grid-pattern)"
              opacity="0.25"
            />
          </div>

          <div
            class="absolute inset-x-0 top-[calc(100%-13rem)] -z-10 transform overflow-hidden blur-3xl sm:top-[calc(100%-30rem)]"
            aria-hidden="true"
          >
            <div
              class="relative left-[calc(50%+3rem)] aspect-[1155/678] w-[36.125rem] -translate-x-1/2 bg-gradient-to-tr from-primary to-secondary opacity-20 sm:left-[calc(50%+36rem)] sm:w-[72.1875rem]"
              style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
            >
            </div>
          </div>
          <!-- Hero content -->
          <div class="mx-auto max-w-7xl px-6 pb-24 pt-36 sm:pt-60 lg:px-8 lg:pt-16">
            <div class="mx-auto max-w-2xl gap-x-14 lg:mx-0 lg:flex lg:max-w-none lg:items-center">
              <div class="lg:-mt-12 relative w-full lg:max-w-xl lg:shrink-0 xl:max-w-3xl">
                <h1 class="text-pretty text-5xl font-semibold tracking-tight text-foreground sm:text-7xl font-display">
                  The open source UpWork alternative.
                </h1>
                <p class="mt-8 text-pretty text-lg font-medium text-muted-foreground sm:max-w-md sm:text-xl/8 lg:max-w-none">
                  GitHub bounties, freelancing and full-time jobs.
                </p>
                <!-- CTA buttons -->
                <div class="mt-10 flex items-center gap-x-6">
                  <.link
                    navigate={~p"/onboarding/org"}
                    class="rounded-md bg-primary px-12 py-5 text-xl font-semibold text-primary-foreground shadow hover:bg-primary/90"
                  >
                    Companies
                  </.link>
                  <.link
                    navigate={~p"/onboarding/dev"}
                    class="rounded-md bg-secondary px-12 py-5 text-xl font-semibold text-secondary-foreground shadow hover:bg-secondary/90"
                  >
                    Developers
                  </.link>
                </div>
                <!-- Stats -->
                <dl class="mt-16 grid grid-cols-2 gap-8 lg:grid-cols-4">
                  <%= for stat <- @stats do %>
                    <div class="flex flex-col gap-y-2">
                      <dt class="text-sm leading-6 text-muted-foreground"><%= stat.label %></dt>
                      <dd class="text-3xl font-semibold tracking-tight text-foreground font-display">
                        <%= stat.value %>
                      </dd>
                    </div>
                  <% end %>
                </dl>
                <!-- Logos -->
                <div class="mt-16">
                  <h2 class="text-sm font-semibold leading-8 text-foreground">
                    Trusted by the world's most innovative teams
                  </h2>
                  <div class="mt-6 grid grid-cols-5 gap-x-8 gap-y-4">
                    <%= for org <- @featured_orgs do %>
                      <img class="max-h-8 w-full object-contain" src={org.avatar_url} alt={org.name} />
                    <% end %>
                  </div>
                </div>
              </div>
              <!-- Featured devs -->
              <%= if length(@featured_devs) > 0 do %>
                <div class="mt-14 flex justify-end gap-8 sm:-mt-44 sm:justify-start sm:pl-20 lg:mt-0 lg:pl-0">
                  <div class="ml-auto w-44 flex-none space-y-8 pt-32 sm:ml-0 sm:pt-80 lg:order-last lg:pt-36 xl:order-none xl:pt-80">
                    <.dev_card dev={List.first(@featured_devs)} />
                  </div>
                  <div class="mr-auto w-44 flex-none space-y-8 sm:mr-0 sm:pt-52 lg:pt-36">
                    <%= if length(@featured_devs) >= 3 do %>
                      <%= for dev <- Enum.slice(@featured_devs, 1..2) do %>
                        <.dev_card dev={dev} />
                      <% end %>
                    <% end %>
                  </div>
                  <div class="w-44 flex-none space-y-8 pt-32 sm:pt-0">
                    <%= for dev <- Enum.slice(@featured_devs, 3..4) do %>
                      <.dev_card dev={dev} />
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
          <!-- New Footer -->
          <footer class="border-t">
            <div class="mx-auto max-w-7xl px-6 py-12 md:flex md:items-center md:justify-between lg:px-8">
              <div class="flex justify-center space-x-6 md:order-2">
                <a href="#" class="text-muted-foreground hover:text-foreground">
                  <span class="sr-only">Twitter</span>
                  <.icon name="tabler-brand-twitter" class="h-6 w-6" />
                </a>
                <a href="#" class="text-muted-foreground hover:text-foreground">
                  <span class="sr-only">GitHub</span>
                  <.icon name="tabler-brand-github" class="h-6 w-6" />
                </a>
                <a href="#" class="text-muted-foreground hover:text-foreground">
                  <span class="sr-only">Discord</span>
                  <.icon name="tabler-brand-discord" class="h-6 w-6" />
                </a>
              </div>
              <div class="mt-8 md:order-1 md:mt-0">
                <p class="text-center text-xs leading-5 text-muted-foreground">
                  &copy; <%= DateTime.utc_now().year %> Algora. All rights reserved.
                </p>
              </div>
            </div>
          </footer>
        </div>
      </main>
    </div>
    """
  end

  def dev_card(assigns) do
    ~H"""
    <div class="relative">
      <img
        src={@dev.avatar_url}
        alt={@dev.name}
        class="aspect-square w-full rounded-xl rounded-b-none bg-muted object-cover shadow-lg ring-1 ring-border"
      />
      <div class="font-display mt-1 p-3 bg-card/50 backdrop-blur-sm rounded-xl rounded-t-none text-sm ring-1 ring-border">
        <div class="font-semibold text-foreground"><%= @dev.name %> <%= @dev.flag %></div>
        <div class="mt-1 text-sm">
          <div class="p-px -ml-1 text-sm flex flex-wrap gap-1 h-6 overflow-hidden">
            <%= for skill <- @dev.skills do %>
              <span class="text-muted-foreground rounded-xl px-2 py-0.5 text-xs ring-1 ring-border bg-muted/50">
                <%= skill %>
              </span>
            <% end %>
          </div>
        </div>
        <div class="mt-1 text-muted-foreground text-xs">
          <span class="font-medium">Total Earned:</span>
          <span class="font-bold text-sm text-foreground">
            <%= @dev.amount |> Money.format!("USD", fractional_digits: 0) %>
          </span>
        </div>
      </div>
    </div>
    """
  end

  def fetch_stats() do
    [
      %{label: "Paid Out", value: "$283,868"},
      %{label: "Completed Bounties", value: "2,240"},
      %{label: "Contributors", value: "509"},
      %{label: "Countries", value: "67"}
    ]
  end

  def list_featured_orgs() do
    [
      %{
        name: "ZIO",
        avatar_url: "https://zio.dev/img/navbar_brand.png",
        url: "https://zio.dev"
      },
      # %{
      #   name: "Tailcall",
      #   avatar_url: "https://tailcall.run/icons/companies/taicall.svg",
      #   url: "https://tailcall.run"
      # },
      %{
        name: "Cal.com",
        avatar_url: "https://cal.com/logo-white.svg",
        url: "https://cal.com"
      },
      %{
        name: "Qdrant",
        avatar_url: "https://qdrant.tech/img/logo.png",
        url: "https://qdrant.tech"
      }
      # %{
      #   name: "Maybe",
      #   avatar_url: "https://maybe.co/assets/logo-1c6733d1.svg",
      #   url: "https://maybe.co"
      # }
    ]
  end
end
