defmodule AlgoraWeb.SwiftBountiesLive do
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Bounties
  import AlgoraWeb.Components.Footer

  alias Algora.Bounties

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bounties.subscribe()
    end

    {:ok,
     socket
     |> assign(:page_title, "Swift Bounties")
     |> assign_tickets()}
  end

  def render(assigns) do
    ~H"""
    <div class="relative isolate overflow-hidden bg-background">
      <svg
        class="absolute inset-0 -z-10 size-full stroke-white/10 [mask-image:radial-gradient(100%_100%_at_top_right,white,transparent)]"
        aria-hidden="true"
      >
        <defs>
          <pattern
            id="983e3e4c-de6d-4c3f-8d64-b9761d1534cc"
            width="200"
            height="200"
            x="50%"
            y="-1"
            patternUnits="userSpaceOnUse"
          >
            <path d="M.5 200V.5H200" fill="none" />
          </pattern>
        </defs>
        <svg x="50%" y="-1" class="overflow-visible fill-gray-800/20">
          <path
            d="M-200 0h201v201h-201Z M600 0h201v201h-201Z M-400 600h201v201h-201Z M200 800h201v201h-201Z"
            stroke-width="0"
          />
        </svg>
        <rect
          width="100%"
          height="100%"
          stroke-width="0"
          fill="url(#983e3e4c-de6d-4c3f-8d64-b9761d1534cc)"
        />
      </svg>
      <div
        class="absolute left-[calc(50%-4rem)] top-10 -z-10 transform blur-3xl sm:left-[calc(50%-18rem)] lg:left-48 lg:top-[calc(50%-30rem)] xl:left-[calc(50%-24rem)]"
        aria-hidden="true"
      >
        <div
          class="aspect-[1108/632] w-[69.25rem] bg-gradient-to-r to-[#ed5236] from-[#fdba74] opacity-20"
          style="clip-path: polygon(73.6% 51.7%, 91.7% 11.8%, 100% 46.4%, 97.4% 82.2%, 92.5% 84.9%, 75.7% 64%, 55.3% 47.5%, 46.5% 49.4%, 45% 62.9%, 50.3% 87.2%, 21.3% 64.1%, 0.1% 100%, 5.4% 51.1%, 21.4% 63.9%, 58.9% 0.2%, 73.6% 51.7%)"
        >
        </div>
      </div>
      <div class="mx-auto max-w-7xl px-6 pb-12 pt-10 sm:pb-16 lg:flex lg:px-8 lg:py-20">
        <div class="mx-auto max-w-2xl shrink-0 lg:mx-0 lg:pt-8">
          <.wordmark />
          <h1 class="mt-10 text-display text-3xl font-semibold tracking-tight text-white sm:text-6xl">
            Fund
            <svg viewBox="0 0 128 128" class="inline-block h-10 w-10 sm:h-16 lg:w-16 -mt-2 ml-2">
              <path
                fill="#f05138"
                d="M126.33 34.06a39.32 39.32 0 00-.79-7.83 28.78 28.78 0 00-2.65-7.58 28.84 28.84 0 00-4.76-6.32 23.42 23.42 0 00-6.62-4.55 27.27 27.27 0 00-7.68-2.53c-2.65-.51-5.56-.51-8.21-.76H30.25a45.46 45.46 0 00-6.09.51 21.82 21.82 0 00-5.82 1.52c-.53.25-1.32.51-1.85.76a33.82 33.82 0 00-5 3.28c-.53.51-1.06.76-1.59 1.26a22.41 22.41 0 00-4.76 6.32 23.61 23.61 0 00-2.65 7.58 78.5 78.5 0 00-.79 7.83v60.39a39.32 39.32 0 00.79 7.83 28.78 28.78 0 002.65 7.58 28.84 28.84 0 004.76 6.32 23.42 23.42 0 006.62 4.55 27.27 27.27 0 007.68 2.53c2.65.51 5.56.51 8.21.76h63.22a45.08 45.08 0 008.21-.76 27.27 27.27 0 007.68-2.53 30.13 30.13 0 006.62-4.55 22.41 22.41 0 004.76-6.32 23.61 23.61 0 002.65-7.58 78.49 78.49 0 00.79-7.83V34.06z"
              >
              </path>
              <path
                fill="#fefefe"
                d="M85 96.5c-11.11 6.13-26.38 6.76-41.75.47A64.53 64.53 0 0113.84 73a50 50 0 0010.85 6.32c15.87 7.1 31.73 6.61 42.9 0-15.9-11.66-29.4-26.82-39.46-39.2a43.47 43.47 0 01-5.29-6.82c12.16 10.61 31.5 24 38.38 27.79a271.77 271.77 0 01-27-32.34 266.8 266.8 0 0044.47 34.87c.71.38 1.26.7 1.7 1a32.7 32.7 0 001.21-3.51c3.71-12.89-.53-27.54-9.79-39.67C93.25 33.81 106 57.05 100.66 76.51c-.14.53-.29 1-.45 1.55l.19.22c10.59 12.63 7.68 26 6.35 23.5C101 91 90.37 94.33 85 96.5z"
              >
              </path>
            </svg>
            <span class="text-[#ff654e] mr-1">Swift</span>
            Together
          </h1>
          <p class="mt-8 text-display text-lg leading-relaxed text-gray-400 sm:text-xl/8">
            Help grow the Swift ecosystem by funding the packages and tools we all depend on. Whether you're a company or individual developer, join us in supporting the Swift open source community.
          </p>
          <div class="mt-10 flex items-center gap-x-6">
            <.link
              href={Algora.Github.authorize_url()}
              rel="noopener"
              class="inline-flex px-8 rounded-md border-white/80 bg-white text-gray-900 transition-colors whitespace-nowrap items-center justify-center font-semibold shadow text-base h-10 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 focus-visible:outline-white-600 disabled:pointer-events-none disabled:opacity-50 hover:border-white hover:bg-white/90 border phx-submit-loading:opacity-75"
            >
              Start Contributing
            </.link>
          </div>
        </div>
        <div class="mx-auto mt-16 flex max-w-2xl sm:mt-24 lg:ml-10 lg:mr-0 lg:mt-0 lg:max-w-none xl:ml-32">
          <div class="max-w-3xl sm:flex-none sm:max-w-5xl lg:max-w-none">
            <.card class="bg-card/25" id="how-it-works">
              <.card_header>
                <.card_title>How It Works</.card_title>
              </.card_header>
              <.card_content>
                <div class="space-y-6">
                  <div class="space-y-2">
                    <.icon name="tabler-diamond" class="h-8 w-8 text-white" />
                    <h3 class="font-semibold">Post Bounties</h3>
                    <div class="text-sm text-muted-foreground space-y-2 sm:space-y-1">
                      <div>
                        Create bounties for Swift issues and pay only when they're solved.
                      </div>
                      <div class="space-x-1">
                        <span>Just comment</span>
                        <code class="inline-block rounded bg-orange-950/75 ring-1 ring-orange-400/25 text-orange-400 px-1 py-0.5 font-mono text-sm">
                          /bounty $1000
                        </code>
                        <span>in any Swift issue or PR.</span>
                      </div>
                    </div>
                  </div>
                  <div class="space-y-2">
                    <.icon name="tabler-users" class="h-8 w-8 text-white" />
                    <h3 class="font-semibold">Pool Resources</h3>
                    <div class="text-sm text-muted-foreground space-y-2 sm:space-y-1">
                      <div>
                        Pool funds with other developers and companies to make bigger impact.
                      </div>
                      <div>
                        We'll collect the funds from all sponsors and pay out to the contributor.
                      </div>
                    </div>
                  </div>
                  <div class="space-y-2">
                    <.icon name="tabler-coin" class="h-8 w-8 text-white" />
                    <h3 class="font-semibold">Send Tips</h3>
                    <div class="text-sm text-muted-foreground space-y-2 sm:space-y-1">
                      <div>
                        Show appreciation for helpful issues and merged pull requests.
                      </div>
                      <div class="space-x-1">
                        <span>Just comment</span>
                        <code class="inline-block rounded bg-orange-950/75 ring-1 ring-orange-400/25 text-orange-400 px-1 py-0.5 font-mono text-sm">
                          /tip $500 @username
                        </code>
                        <span>in any Swift issue or PR.</span>
                      </div>
                    </div>
                  </div>
                </div>
              </.card_content>
            </.card>
          </div>
        </div>
      </div>
    </div>

    <div class="py-24 sm:py-32">
      <div class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8">
        <h2 class="text-center text-base/7 font-semibold text-orange-400">
          Reward contributions
        </h2>
        <p class="text-center mt-2 text-display text-3xl font-semibold tracking-tight text-white sm:text-5xl">
          You don't even need to leave GitHub
        </p>
        <div class="mt-10 grid grid-cols-1 gap-4 sm:mt-16 lg:grid-cols-7">
          <div class="flex p-px lg:col-span-4">
            <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 max-lg:rounded-t-[2rem] lg:rounded-tl-[2rem]">
              <img class="object-cover object-left" src={~p"/images/screenshots/bounty.png"} alt="" />
              <div class="p-4 sm:p-6">
                <h3 class="text-sm/4 font-semibold text-gray-400">Bounties</h3>
                <p class="mt-2 text-lg font-medium tracking-tight text-white">
                  Fund Issues
                </p>
                <p class="mt-2 text-sm/6 text-gray-400">
                  Create bounties on any Swift issue to incentivize solutions and attract talented contributors
                </p>
              </div>
            </div>
          </div>
          <div class="flex p-px lg:col-span-3">
            <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 lg:rounded-tr-[2rem]">
              <img class="object-cover" src={~p"/images/screenshots/tip.png"} alt="" />
              <div class="p-4 sm:p-6">
                <h3 class="text-sm/4 font-semibold text-gray-400">Tips</h3>
                <p class="mt-2 text-lg font-medium tracking-tight text-white">
                  Show Appreciation
                </p>
                <p class="mt-2 text-sm/6 text-gray-400">
                  Say thanks with tips to recognize valuable contributions
                </p>
              </div>
            </div>
          </div>
          <div class="flex p-px lg:col-span-3">
            <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 lg:rounded-bl-[2rem]">
              <div class="flex object-cover">
                <div class="flex h-full w-full gap-x-4 p-4 pb-0 sm:gap-x-6 items-center justify-center">
                  <div class="flex flex-col w-full sm:w-auto space-y-3 sm:py-9">
                    <div
                      class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
                      style="opacity: 1; transform: translateX(0.2px) translateZ(0px);"
                    >
                      <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 20 20"
                          fill="currentColor"
                          aria-hidden="true"
                          class="h-4 w-4 text-emerald-500"
                        >
                          <path
                            fill-rule="evenodd"
                            d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                            clip-rule="evenodd"
                          >
                          </path>
                        </svg>
                        <p class="pb-8 font-sans text-sm text-gray-200 last:pb-0">
                          Merged pull request
                        </p>
                      </div>
                    </div>
                    <div
                      class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
                      style="opacity: 1; transform: translateX(0.2px) translateZ(0px);"
                    >
                      <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 20 20"
                          fill="currentColor"
                          aria-hidden="true"
                          class="h-4 w-4 text-emerald-500 "
                        >
                          <path
                            fill-rule="evenodd"
                            d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                            clip-rule="evenodd"
                          >
                          </path>
                        </svg>
                        <p class="pb-8 font-sans text-sm text-gray-200 last:pb-0">
                          Completed payment
                        </p>
                      </div>
                    </div>
                    <div
                      class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
                      style="opacity: 0.7; transform: translateX(0.357815px) translateZ(0px);"
                    >
                      <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
                        <svg
                          width="20"
                          height="20"
                          viewBox="0 0 20 20"
                          fill="none"
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4 animate-spin motion-reduce:hidden"
                        >
                          <rect
                            x="2"
                            y="2"
                            width="16"
                            height="16"
                            rx="8"
                            stroke="rgba(59, 130, 246, 0.4)"
                            stroke-width="3"
                          >
                          </rect>
                          <path
                            d="M10 18C5.58172 18 2 14.4183 2 10C2 5.58172 5.58172 2 10 2"
                            stroke="rgba(59, 130, 246)"
                            stroke-width="3"
                            stroke-linecap="round"
                          >
                          </path>
                        </svg>
                        <p class="pb-8 font-sans text-sm text-gray-400 last:pb-0">
                          Transferring funds to contributor
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="p-4 sm:p-6">
                <h3 class="text-sm/4 font-semibold text-gray-400">Payments</h3>
                <p class="mt-2 text-lg font-medium tracking-tight text-white">
                  Pay When Merged
                </p>
                <p class="mt-2 text-sm/6 text-gray-400">
                  Set up auto-pay to instantly reward contributors as their PRs are merged
                </p>
              </div>
            </div>
          </div>
          <div class="flex p-px lg:col-span-4">
            <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 max-lg:rounded-b-[2rem] lg:rounded-br-[2rem]">
              <img class="object-cover object-left" src={~p"/images/screenshots/bounties.png"} alt="" />
              <div class="p-4 sm:p-6">
                <h3 class="text-sm/4 font-semibold text-gray-400">Pooling</h3>
                <p class="mt-2 text-lg font-medium tracking-tight text-white">
                  Fund Together
                </p>
                <p class="mt-2 text-sm/6 text-gray-400">
                  Companies and individuals can pool their money together to fund important Swift improvements
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="container max-w-7xl mx-auto px-6 space-y-12">
      <%= if Enum.empty?(@tickets) do %>
        <.card class="text-center bg-card py-12 rounded-lg lg:rounded-[2rem]">
          <.card_header>
            <div class="mx-auto rounded-full bg-muted p-4 mb-2">
              <.icon name="tabler-diamond" class="w-8 h-8 text-muted-foreground" />
            </div>
            <.card_title>No bounties yet</.card_title>
            <.card_description>
              Open bounties will appear here once created
            </.card_description>
          </.card_header>
        </.card>
      <% else %>
        <.card class="bg-card rounded-lg lg:rounded-[2rem]">
          <.card_header class="flex justify-between">
            <.card_title>Open Bounties</.card_title>
          </.card_header>
          <.card_content>
            <.bounties tickets={@tickets} />
            <div class="pt-4 justify-center hidden">
              <.button variant="ghost" phx-click="load_more">
                <.icon name="tabler-arrow-down" class="w-4 h-4 mr-2" /> Load More
              </.button>
            </div>
          </.card_content>
        </.card>
      <% end %>
    </div>

    <div class="relative">
      <.footer />
    </div>
    """
  end

  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_tickets(socket)}
  end

  defp assign_tickets(socket) do
    tickets =
      Bounties.TicketView.list(
        status: :open,
        tech_stack: ["Swift"],
        limit: 100
      )

    socket |> assign(:tickets, tickets)
  end
end
