defmodule AlgoraWeb.HomeLive do
  use AlgoraWeb, :live_view
  alias Algora.Accounts
  alias Algora.Money

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:featured_devs, Accounts.list_featured_devs())
     |> assign(:featured_orgs, list_featured_orgs())
     |> assign(:stats, fetch_stats())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gradient-to-tl from-indigo-950 to-black">
      <header class="absolute inset-x-0 top-0 z-50">
        <nav
          class="mx-auto flex max-w-7xl items-center justify-between p-6 lg:px-8"
          aria-label="Global"
        >
          <div class="flex lg:flex-1">
            <.wordmark class="text-white h-8 w-auto" />
          </div>
          <div class="flex lg:hidden">
            <button
              type="button"
              class="-m-2.5 inline-flex items-center justify-center rounded-md p-2.5 text-gray-700"
            >
              <span class="sr-only">Open main menu</span>
              <svg
                class="h-6 w-6"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                aria-hidden="true"
                data-slot="icon"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
                />
              </svg>
            </button>
          </div>
          <div class="hidden lg:flex lg:gap-x-12">
            <a href="#" class="text-sm/6 font-semibold text-gray-300 hover:text-white">Product</a>
            <a href="#" class="text-sm/6 font-semibold text-gray-300 hover:text-white">Features</a>
            <a href="#" class="text-sm/6 font-semibold text-gray-300 hover:text-white">Marketplace</a>
            <a href="#" class="text-sm/6 font-semibold text-gray-300 hover:text-white">Company</a>
          </div>
          <div class="hidden lg:flex lg:flex-1 lg:justify-end">
            <.link
              navigate={~p"/auth/login"}
              class="text-sm/6 font-semibold text-gray-300 hover:text-white"
            >
              Log in <span aria-hidden="true">&rarr;</span>
            </.link>
          </div>
        </nav>
        <!-- Mobile menu, show/hide based on menu open state. -->
        <div class="lg:hidden" role="dialog" aria-modal="true">
          <!-- Background backdrop, show/hide based on slide-over state. -->
          <div class="fixed inset-0 z-50"></div>
          <div class="fixed inset-y-0 right-0 z-50 w-full overflow-y-auto bg-gray-900 px-6 py-6 sm:max-w-sm sm:ring-1 sm:ring-white/10">
            <div class="flex items-center justify-between">
              <a href="#" class="-m-1.5 p-1.5">
                <span class="sr-only">Your Company</span>
                <img
                  class="h-8 w-auto"
                  src="https://tailwindui.com/plus/img/logos/mark.svg?color=indigo&shade=600"
                  alt=""
                />
              </a>
              <button type="button" class="-m-2.5 rounded-md p-2.5 text-gray-700">
                <span class="sr-only">Close menu</span>
                <svg
                  class="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  aria-hidden="true"
                  data-slot="icon"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
            <div class="mt-6 flow-root">
              <div class="-my-6 divide-y divide-gray-500/10">
                <div class="space-y-2 py-6">
                  <a
                    href="#"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-gray-300 hover:bg-gray-800"
                  >
                    Product
                  </a>
                  <a
                    href="#"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-gray-300 hover:bg-gray-800"
                  >
                    Features
                  </a>
                  <a
                    href="#"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-gray-300 hover:bg-gray-800"
                  >
                    Marketplace
                  </a>
                  <a
                    href="#"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-gray-300 hover:bg-gray-800"
                  >
                    Company
                  </a>
                </div>
                <div class="py-6">
                  <a
                    href="#"
                    class="-mx-3 block rounded-lg px-3 py-2.5 text-base/7 font-semibold text-gray-300 hover:bg-gray-800"
                  >
                    Log in
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </header>
      <main>
        <div class="relative isolate">
          <svg
            class="absolute inset-x-0 top-0 -z-10 h-[64rem] w-full stroke-gray-700 [mask-image:radial-gradient(32rem_32rem_at_center,white,transparent)]"
            aria-hidden="true"
          >
            <defs>
              <pattern
                id="1f932ae7-37de-4c0a-a8b0-a6e3b4d44b84"
                width="200"
                height="200"
                x="50%"
                y="-1"
                patternUnits="userSpaceOnUse"
              >
                <path d="M.5 200V.5H200" fill="none" />
              </pattern>
            </defs>
            <svg x="50%" y="-1" class="overflow-visible fill-gray-900">
              <path
                d="M-200 0h201v201h-201Z M600 0h201v201h-201Z M-400 600h201v201h-201Z M200 800h201v201h-201Z"
                stroke-width="0"
              />
            </svg>
            <rect
              width="100%"
              height="100%"
              stroke-width="0"
              fill="url(#1f932ae7-37de-4c0a-a8b0-a6e3b4d44b84)"
              opacity="0.25"
            />
          </svg>
          <div
            class="absolute left-1/2 right-0 top-0 -z-10 -ml-24 transform overflow-hidden blur-3xl lg:ml-24 xl:ml-48"
            aria-hidden="true"
          >
            <div
              class="aspect-[801/1036] w-[50.0625rem] bg-gradient-to-tr from-[#a78bfa] to-[#818cf8] opacity-30"
              style="clip-path: polygon(63.1% 29.5%, 100% 17.1%, 76.6% 3%, 48.4% 0%, 44.6% 4.7%, 54.5% 25.3%, 59.8% 49%, 55.2% 57.8%, 44.4% 57.2%, 27.8% 47.9%, 35.1% 81.5%, 0% 97.7%, 39.2% 100%, 35.2% 81.4%, 97.2% 52.8%, 63.1% 29.5%)"
            >
            </div>
          </div>
          <div class="overflow-hidden">
            <div class="mx-auto max-w-7xl px-6 pb-32 pt-36 sm:pt-60 lg:px-8 lg:pt-16">
              <div class="mx-auto max-w-2xl gap-x-14 lg:mx-0 lg:flex lg:max-w-none lg:items-center">
                <div class="lg:-mt-12 relative w-full lg:max-w-xl lg:shrink-0 xl:max-w-3xl">
                  <h1 class="text-pretty text-5xl font-semibold tracking-tight text-white sm:text-7xl font-display">
                    Open Source UpWork <br /> for Developers
                  </h1>
                  <p class="mt-8 text-pretty text-lg font-medium text-gray-300 sm:max-w-md sm:text-xl/8 lg:max-w-none">
                    GitHub bounties, freelancing and full-time jobs.
                  </p>

                  <div class="mt-10 flex items-center gap-x-6">
                    <.link
                      navigate={~p"/onboarding/org"}
                      class="rounded-md bg-indigo-500 px-12 py-5 text-xl font-semibold text-white shadow-sm hover:bg-indigo-400"
                    >
                      Companies
                    </.link>
                    <.link
                      navigate={~p"/onboarding/dev"}
                      class="rounded-md bg-gray-800 px-12 py-5 text-xl font-semibold text-white shadow-sm ring-1 ring-inset ring-gray-700 hover:bg-gray-700"
                    >
                      Developers
                    </.link>
                  </div>
                  <!-- Stats Section -->
                  <dl class="mt-16 grid grid-cols-2 gap-8 lg:grid-cols-4">
                    <%= for stat <- @stats do %>
                      <div class="flex flex-col gap-y-2">
                        <dt class="text-sm leading-6 text-gray-400"><%= stat.label %></dt>
                        <dd class="text-3xl font-semibold tracking-tight text-white font-display">
                          <%= stat.value %>
                        </dd>
                      </div>
                    <% end %>
                  </dl>
                  <!-- Logos Section -->
                  <div class="mt-16">
                    <h2 class="text-sm font-semibold leading-8 text-white">
                      Trusted by the world's most innovative teams
                    </h2>
                    <div class="mt-6 grid grid-cols-5 gap-x-8 gap-y-4">
                      <%= for org <- @featured_orgs do %>
                        <img
                          class="max-h-8 w-full object-contain"
                          src={org.avatar_url}
                          alt={org.name}
                        />
                      <% end %>
                    </div>
                  </div>
                </div>
                <!-- Featured Devs Section -->
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
              </div>
            </div>
          </div>
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
        class="aspect-square w-full rounded-xl rounded-b-none bg-gray-800/5 object-cover shadow-lg ring-1 ring-gray-700"
      />
      <div class="font-display mt-1 p-3 bg-gray-900/50 backdrop-blur-sm rounded-xl rounded-t-none text-sm ring-1 ring-gray-700">
        <div class="font-semibold text-white"><%= @dev.name %> <%= @dev.flag %></div>
        <div class="mt-1 text-sm">
          <div class="p-px -ml-1 text-sm flex flex-wrap gap-1 h-6 overflow-hidden">
            <%= for skill <- @dev.skills do %>
              <span class="text-gray-300 rounded-xl px-2 py-0.5 text-xs ring-1 ring-gray-700 bg-gray-800/50">
                <%= skill %>
              </span>
            <% end %>
          </div>
        </div>
        <div class="mt-1 text-gray-300 text-xs">
          <span class="font-medium">Total Earned:</span>
          <span class="font-bold text-sm text-white">
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
