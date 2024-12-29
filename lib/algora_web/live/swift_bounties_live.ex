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
          class="aspect-[1108/632] w-[69.25rem] bg-gradient-to-r from-[#5eead4] to-[#059669] opacity-20"
          style="clip-path: polygon(73.6% 51.7%, 91.7% 11.8%, 100% 46.4%, 97.4% 82.2%, 92.5% 84.9%, 75.7% 64%, 55.3% 47.5%, 46.5% 49.4%, 45% 62.9%, 50.3% 87.2%, 21.3% 64.1%, 0.1% 100%, 5.4% 51.1%, 21.4% 63.9%, 58.9% 0.2%, 73.6% 51.7%)"
        >
        </div>
      </div>
      <div class="mx-auto max-w-7xl px-6 pb-12 pt-10 sm:pb-16 lg:flex lg:px-8 lg:py-20">
        <div class="mx-auto max-w-2xl shrink-0 lg:mx-0 lg:pt-8">
          <.wordmark />
          <h1 class="mt-10 text-pretty text-5xl font-semibold tracking-tight text-white sm:text-7xl">
            <.icon name="tabler-brand-swift" class="inline-block h-20 w-20 -mt-2 mr-1" />
            Fund Swift Projects Together
          </h1>
          <p class="mt-8 text-pretty text-lg leading-relaxed text-gray-400 sm:text-xl/8">
            Help grow the Swift ecosystem by funding the packages and tools we all depend on. Whether you're a company or individual developer, join us in supporting the Swift open source community.
          </p>
          <div class="mt-10 flex items-center gap-x-6">
            <.link navigate={~p"/auth/login"}>
              <.button size="lg">Start Contributing</.button>
            </.link>
          </div>
        </div>
        <div class="mx-auto mt-16 flex max-w-2xl sm:mt-24 lg:ml-10 lg:mr-0 lg:mt-0 lg:max-w-none xl:ml-32">
          <div class="max-w-3xl flex-none sm:max-w-5xl lg:max-w-none">
            <.card class="bg-card/25" id="how-it-works">
              <.card_header>
                <.card_title>How It Works</.card_title>
              </.card_header>
              <.card_content>
                <div class="space-y-6">
                  <div class="space-y-2">
                    <.icon name="tabler-diamond" class="h-8 w-8 text-primary" />
                    <h3 class="font-semibold">Post Bounties</h3>
                    <div class="text-sm text-muted-foreground space-y-1">
                      <div>
                        Create bounties for Swift issues and pay only when they're solved.
                      </div>
                      <div class="space-x-1">
                        <span>Just comment</span>
                        <code class="inline-block rounded bg-emerald-950/75 ring-1 ring-success/25 text-success px-1 py-0.5 font-mono text-sm">
                          /bounty $1000
                        </code>
                        <span>in any Swift issue or PR.</span>
                      </div>
                    </div>
                  </div>
                  <div class="space-y-2">
                    <.icon name="tabler-users" class="h-8 w-8 text-primary" />
                    <h3 class="font-semibold">Pool Resources</h3>
                    <div class="text-sm text-muted-foreground space-y-1">
                      <div>
                        Pool funds with other developers and companies to make bigger impact.
                      </div>
                      <div>
                        We'll collect the funds from all sponsors and pay out to the contributor.
                      </div>
                    </div>
                  </div>
                  <div class="space-y-2">
                    <.icon name="tabler-coin" class="h-8 w-8 text-primary" />
                    <h3 class="font-semibold">Send Tips</h3>
                    <div class="text-sm text-muted-foreground space-y-1">
                      <div>
                        Show appreciation for helpful issues and merged pull requests.
                      </div>
                      <div class="space-x-1">
                        <span>Just comment</span>
                        <code class="inline-block rounded bg-emerald-950/75 ring-1 ring-success/25 text-success px-1 py-0.5 font-mono text-sm">
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
        <h2 class="text-center text-base/7 font-semibold text-success">
          Reward contributions
        </h2>
        <p class="text-center mt-2 text-pretty text-4xl font-semibold tracking-tight text-white sm:text-5xl">
          You don't even need to leave GitHub
        </p>
        <div class="mt-10 grid grid-cols-1 gap-4 sm:mt-16 lg:grid-cols-7 lg:grid-rows-2">
          <div class="flex p-px lg:col-span-4">
            <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 max-lg:rounded-t-[2rem] lg:rounded-tl-[2rem]">
              <img class="object-cover object-left" src={~p"/images/screenshots/bounty.png"} alt="" />
              <div class="p-10">
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
              <div class="p-10">
                <h3 class="text-sm/4 font-semibold text-gray-400">Tips</h3>
                <p class="mt-2 text-lg font-medium tracking-tight text-white">
                  Show Appreciation
                </p>
                <p class="mt-2 text-sm/6 text-gray-400">
                  Say thanks with tips to recognize valuable contributions - from helpful issues to merged pull requests
                </p>
              </div>
            </div>
          </div>
          <div class="flex p-px lg:col-span-2">
            <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 lg:rounded-bl-[2rem]">
              <div class="flex object-cover">
                <div class="flex h-full w-full gap-x-4 p-4 sm:gap-x-6 items-center justify-center">
                  <div class="flex flex-col space-y-3 px-6 py-12">
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
              <div class="p-10">
                <h3 class="text-sm/4 font-semibold text-gray-400">Payments</h3>
                <p class="mt-2 text-lg font-medium tracking-tight text-white">
                  Pay When Merged
                </p>
                <p class="mt-2 text-sm/6 text-gray-400">
                  Only pay when work is complete - set up auto-pay to instantly reward contributors when their PRs are merged
                </p>
              </div>
            </div>
          </div>
          <div class="flex p-px lg:col-span-5">
            <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 max-lg:rounded-b-[2rem] lg:rounded-br-[2rem]">
              <img class="object-cover object-left" src={~p"/images/screenshots/bounties.png"} alt="" />
              <div class="p-10">
                <h3 class="text-sm/4 font-semibold text-gray-400">Pooling</h3>
                <p class="mt-2 text-lg font-medium tracking-tight text-white">
                  Fund Together
                </p>
                <p class="mt-2 text-sm/6 text-gray-400">
                  Companies and individuals can pool their money together to fund important Swift ecosystem improvements
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
