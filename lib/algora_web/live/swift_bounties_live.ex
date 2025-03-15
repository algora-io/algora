defmodule AlgoraWeb.SwiftBountiesLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Bounties
  import AlgoraWeb.Components.Footer
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Github
  alias Algora.Repo
  alias Algora.Workspace
  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.TipForm
  alias AlgoraWeb.UserAuth

  require Logger

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bounties.subscribe()
      Phoenix.PubSub.subscribe(Algora.PubSub, "auth:#{socket.id}")
    end

    socket =
      case socket.assigns[:current_user] do
        nil ->
          socket
          |> assign(:page_title, "Fund Swift Together")
          |> assign(:page_description, "Help grow the Swift ecosystem by funding the work we all depend on.")
          |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/og/swift.png")
          |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
          |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
          |> assign(:oauth_url, Github.authorize_url(%{socket_id: socket.id}))
          |> assign(:pending_action, nil)
          |> assign_bounties()
          |> assign_active_repos()

        current_user ->
          redirect(socket, to: UserAuth.signed_in_path(current_user))
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="relative isolate overflow-hidden bg-background">
      <svg
        class="[mask-image:radial-gradient(100%_100%_at_top_right,white,transparent)] absolute inset-0 -z-10 size-full stroke-white/10"
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
        class="left-[calc(50%-4rem)] absolute top-10 -z-10 transform blur-3xl sm:left-[calc(50%-18rem)] lg:top-[calc(50%-30rem)] lg:left-48 xl:left-[calc(50%-24rem)]"
        aria-hidden="true"
      >
        <div
          class="aspect-[1108/632] w-[69.25rem] to-[#ed5236] from-[#fdba74] bg-gradient-to-r opacity-20"
          style="clip-path: polygon(73.6% 51.7%, 91.7% 11.8%, 100% 46.4%, 97.4% 82.2%, 92.5% 84.9%, 75.7% 64%, 55.3% 47.5%, 46.5% 49.4%, 45% 62.9%, 50.3% 87.2%, 21.3% 64.1%, 0.1% 100%, 5.4% 51.1%, 21.4% 63.9%, 58.9% 0.2%, 73.6% 51.7%)"
        >
        </div>
      </div>
      <div class="mx-auto max-w-7xl px-6 py-3 pb-12 sm:pb-16 lg:flex lg:px-8 lg:pb-20 xl:pb-0 xl:min-h-screen xl:items-center">
        <div class="mx-auto max-w-2xl shrink-0 lg:mx-0 lg:pt-8 xl:pt-0">
          <.wordmark />
          <h1 class="font-display mt-10 text-2xl font-semibold tracking-tight text-white sm:text-6xl">
            Fund
            <svg viewBox="0 0 128 128" class="-mt-2 ml-2 inline-block h-10 w-10 sm:h-16 lg:w-16">
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
          <p class="mt-8 text-lg font-medium leading-relaxed text-gray-300 sm:text-xl/8">
            Help grow the Swift ecosystem by funding the work we all depend on.
          </p>
          <p class="mt-4 text-lg font-medium leading-relaxed text-gray-300 sm:text-xl/8">
            Anyone can contribute whether you're a company or an individual.
          </p>
          <div class="mt-10 flex items-center gap-x-6">
            <.button
              href={Algora.Github.authorize_url()}
              rel="noopener"
              variant="subtle"
              class="h-12 px-6 text-lg font-semibold"
            >
              Start Contributing
            </.button>
          </div>
        </div>
        <div class="mx-auto mt-16 flex max-w-2xl sm:mt-24 lg:mt-0 lg:mr-0 lg:ml-10 lg:max-w-none xl:ml-24 2xl:ml-32">
          <div class="max-w-3xl sm:max-w-5xl sm:flex-none lg:max-w-none">
            <.card class="-mx-3 bg-card/25 sm:mx-0" id="how-it-works">
              <.card_header class="-mx-3 sm:mx-0">
                <.card_title>How It Works</.card_title>
              </.card_header>
              <.card_content class="-mx-3 sm:mx-0">
                <div class="space-y-10 pt-4 sm:space-y-6 sm:pt-0">
                  <div class="space-y-2">
                    <div class="flex items-center gap-2 sm:flex-col sm:items-start">
                      <.icon name="tabler-diamond" class="h-8 w-8 text-white" />
                      <h3 class="font-semibold">Post Bounties</h3>
                    </div>
                    <div class="space-y-2 text-sm font-medium text-muted-foreground sm:space-y-1">
                      <div>
                        Create bounties for Swift issues and pay only when they're solved.
                      </div>
                      <div class="space-x-1">
                        <span>Just comment</span>
                        <code class="inline-block rounded bg-orange-950/75 px-1 py-0.5 font-mono text-sm text-orange-400 ring-1 ring-orange-400/25">
                          /bounty $1000
                        </code>
                        <span>in any Swift issue or PR.</span>
                      </div>
                    </div>
                  </div>
                  <div class="space-y-2">
                    <div class="flex items-center gap-2 sm:flex-col sm:items-start">
                      <.icon name="tabler-users" class="h-8 w-8 text-white" />
                      <h3 class="font-semibold">Pool Resources</h3>
                    </div>
                    <div class="space-y-2 text-sm font-medium text-muted-foreground sm:space-y-1">
                      <div>
                        Pool funds with other developers and companies to make bigger impact.
                      </div>
                      <div>
                        We'll collect the funds from all sponsors and pay out to the contributor(s).
                      </div>
                    </div>
                  </div>
                  <div class="space-y-2">
                    <div class="flex items-center gap-2 sm:flex-col sm:items-start">
                      <.icon name="tabler-coin" class="h-8 w-8 text-white" />
                      <h3 class="font-semibold">Send Tips</h3>
                    </div>
                    <div class="space-y-2 text-sm font-medium text-muted-foreground sm:space-y-1">
                      <div>
                        Show appreciation for helpful issues and merged pull requests.
                      </div>
                      <div class="space-x-1">
                        <span>Just comment</span>
                        <code class="inline-block rounded bg-orange-950/75 px-1 py-0.5 font-mono text-sm text-orange-400 ring-1 ring-orange-400/25">
                          /tip $500 @username
                        </code>
                        <span>in any Swift issue or PR.</span>
                      </div>
                    </div>
                  </div>

                  <div class="space-y-2">
                    <div class="flex items-center gap-2 sm:flex-col sm:items-start">
                      <.icon name="tabler-contract" class="h-8 w-8 text-white" />
                      <div class="flex items-center gap-2">
                        <h3 class="font-semibold">Start Contracts</h3>
                        <span class="rounded bg-gray-950/75 px-2 py-0.5 text-xs font-medium text-gray-400 ring-1 ring-gray-400/25">
                          Coming Soon
                        </span>
                      </div>
                    </div>
                    <div class="space-y-2 text-sm font-medium text-muted-foreground sm:space-y-1">
                      <div>
                        Engage contributors for longer-term Swift development work.
                      </div>
                      <div class="space-x-1">
                        <span>Just comment</span>
                        <code class="inline-block rounded bg-orange-950/75 px-1 py-0.5 font-mono text-sm text-orange-400 ring-1 ring-orange-400/25">
                          /contract $5000 @username
                        </code>
                        <span>to offer a contract.</span>
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
      <div class="mx-auto max-w-2xl px-6 lg:max-w-4xl lg:px-8">
        <h2 class="text-center text-base/7 font-semibold text-orange-400">
          Start Contributing
        </h2>
        <p class="font-display mt-2 text-center text-3xl font-semibold tracking-tight text-white sm:text-5xl">
          Fund Swift Development in Seconds
        </p>
        <div class="mt-5 grid grid-cols-1 gap-5 sm:gap-8 sm:mt-8 lg:grid-cols-2">
          {create_bounty(assigns)}
          {create_tip(assigns)}
        </div>
      </div>
    </div>

    <div class="py-24 sm:py-32">
      <div class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8">
        <h2 class="text-center text-base/7 font-semibold text-orange-400">
          Reward contributions
        </h2>
        <p class="font-display mt-2 text-center text-3xl font-semibold tracking-tight text-white sm:text-5xl">
          You don't even need to leave GitHub
        </p>
        <div class="mt-10 grid grid-cols-1 gap-4 sm:mt-16 lg:grid-cols-[repeat(14,_minmax(0,_1fr))]">
          <div class="flex p-px lg:col-span-8">
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
          <div class="flex p-px lg:col-span-6">
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
          <div class="flex p-px lg:col-span-6">
            <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15">
              <div class="flex object-cover">
                <div class="flex h-full w-full items-center justify-center gap-x-4 p-4 pb-0 sm:gap-x-6">
                  <div class="flex w-full flex-col space-y-3 sm:w-auto sm:py-9">
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
                          class="h-4 w-4 text-success-500"
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
                          class="h-4 w-4 text-success-500"
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
          <div class="flex p-px lg:col-span-8">
            <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15">
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
          <div class="flex p-px lg:col-span-5">
            <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 lg:rounded-bl-[2rem]">
              <img
                class="object-cover object-left"
                src={~p"/images/screenshots/payout-account.png"}
                alt=""
              />
              <div class="p-4 sm:p-6">
                <h3 class="text-sm/4 font-semibold text-gray-400">Payouts</h3>
                <p class="mt-2 text-lg font-medium tracking-tight text-white">
                  Fast, Global Payouts
                </p>
                <p class="mt-2 text-sm/6 text-gray-400">
                  Receive payments directly to your bank account from all around the world
                  <span class="font-medium text-foreground">(120 countries supported)</span>
                </p>
              </div>
            </div>
          </div>
          <div class="flex p-px lg:col-span-9">
            <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 max-lg:rounded-b-[2rem] lg:rounded-br-[2rem]">
              <img class="object-cover" src={~p"/images/screenshots/contract.png"} alt="" />
              <div class="p-4 sm:p-6">
                <h3 class="text-sm/4 font-semibold text-gray-400">Contracts (coming soon)</h3>
                <p class="mt-2 text-lg font-medium tracking-tight text-white">
                  Flexible Engagement
                </p>
                <p class="mt-2 text-sm/6 text-gray-400">
                  Set hourly rates, weekly hours, and payment schedules for ongoing Swift development work. Track progress and manage payments all in one place.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="container mx-auto max-w-7xl space-y-12 px-6">
      <%= if Enum.empty?(@bounties) do %>
        <.card class="rounded-[2rem] bg-card py-12 text-center">
          <.card_header>
            <div class="mx-auto mb-2 rounded-full bg-muted p-4">
              <.icon name="tabler-diamond" class="h-8 w-8 text-muted-foreground" />
            </div>
            <.card_title>No bounties yet</.card_title>
            <.card_description>
              Open bounties will appear here once created
            </.card_description>
          </.card_header>
        </.card>
      <% else %>
        <.card class="rounded-[2rem] bg-card">
          <.card_header class="flex justify-between">
            <.card_title>Open Bounties</.card_title>
          </.card_header>
          <.card_content>
            <.bounties bounties={@bounties} />
            <div class="hidden justify-center pt-4">
              <.button variant="ghost" phx-click="load_more">
                <.icon name="tabler-arrow-down" class="mr-2 h-4 w-4" /> Load More
              </.button>
            </div>
          </.card_content>
        </.card>
      <% end %>
    </div>

    <div class="mx-auto max-w-7xl py-24 sm:px-6 sm:py-32 lg:px-8">
      <div class="relative isolate overflow-hidden px-6 text-center shadow-2xl sm:rounded-3xl sm:px-16">
        <div class="flex items-center justify-center gap-4">
          <code class="inline-block rounded bg-orange-950/75 px-1 py-0.5 font-mono text-sm text-orange-400 ring-1 ring-orange-400/25">
            /bounty $1000
          </code>
          <code class="inline-block rounded bg-orange-950/75 px-1 py-0.5 font-mono text-sm text-orange-400 ring-1 ring-orange-400/25">
            /tip $500 @username
          </code>
        </div>
        <h2 class="mt-6 text-balance font-display text-4xl font-semibold tracking-tight text-white sm:text-5xl">
          Get Started Now
        </h2>
        <p class="mx-auto mt-6 max-w-xl font-medium text-lg/8 text-gray-300">
          You can create bounties and send tips in any of the Swift repos below once you've connected your GitHub account.
        </p>
        <div class="mt-6 flex items-center justify-center gap-x-6">
          <.button
            href={Algora.Github.authorize_url()}
            rel="noopener"
            variant="subtle"
            class="h-12 px-6 text-lg font-semibold inline-flex items-center"
          >
            <Logos.github class="-ml-1 mr-2 h-6 w-6 sm:h-8 sm:w-8" /> Connect with GitHub
          </.button>
        </div>
        <div class="mt-10 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for repo <- @repos do %>
            <.link href={repo.url}>
              <img
                src={repo.og_image_url}
                alt={repo.name}
                class="rounded-lg aspect-[1200/630] w-full h-full bg-muted"
              />
            </.link>
          <% end %>
        </div>
      </div>
    </div>

    <div class="relative">
      <.footer />
    </div>
    """
  end

  defp create_bounty(assigns) do
    ~H"""
    <.card class="bg-muted/30">
      <.card_header>
        <div class="flex items-center gap-3">
          <.icon name="tabler-diamond" class="h-8 w-8" />
          <h2 class="text-2xl font-semibold">Post a bounty</h2>
        </div>
      </.card_header>
      <.card_content>
        <.simple_form for={@bounty_form} phx-submit="create_bounty">
          <div class="flex flex-col gap-6">
            <.input
              label="URL"
              field={@bounty_form[:url]}
              placeholder="https://github.com/swift-lang/swift/issues/1337"
            />
            <.input label="Amount" icon="tabler-currency-dollar" field={@bounty_form[:amount]} />
            <div class="flex justify-end gap-4">
              <.button variant="subtle">Submit</.button>
            </div>
          </div>
        </.simple_form>
      </.card_content>
    </.card>
    """
  end

  defp create_tip(assigns) do
    ~H"""
    <.card class="bg-muted/30">
      <.card_header>
        <div class="flex items-center gap-3">
          <.icon name="tabler-gift" class="h-8 w-8" />
          <h2 class="text-2xl font-semibold">Tip a developer</h2>
        </div>
      </.card_header>
      <.card_content>
        <.simple_form for={@tip_form} phx-submit="create_tip">
          <div class="flex flex-col gap-6">
            <.input label="GitHub handle" field={@tip_form[:github_handle]} placeholder="jsmith" />
            <.input label="Amount" icon="tabler-currency-dollar" field={@tip_form[:amount]} />
            <div class="flex justify-end gap-4">
              <.button variant="subtle">Submit</.button>
            </div>
          </div>
        </.simple_form>
      </.card_content>
    </.card>
    """
  end

  def handle_event("create_bounty" = event, %{"bounty_form" => params} = unsigned_params, socket) do
    changeset =
      %BountyForm{}
      |> BountyForm.changeset(params)
      |> Map.put(:action, :validate)

    amount = get_field(changeset, :amount)
    ticket_ref = get_field(changeset, :ticket_ref)

    if changeset.valid? do
      if socket.assigns[:current_user] do
        case Bounties.create_bounty(%{
               creator: socket.assigns.current_user,
               owner: socket.assigns.current_user,
               amount: amount,
               ticket_ref: ticket_ref
             }) do
          {:ok, _bounty} ->
            {:noreply,
             socket
             |> put_flash(:info, "Bounty created")
             |> redirect(to: ~p"/")}

          {:error, :already_exists} ->
            {:noreply, put_flash(socket, :warning, "You have already created a bounty for this ticket")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Something went wrong")}
        end
      else
        {:noreply,
         socket
         |> assign(:pending_action, {event, unsigned_params})
         |> push_event("open_popup", %{url: socket.assigns.oauth_url})}
      end
    else
      {:noreply, assign(socket, :bounty_form, to_form(changeset))}
    end
  end

  def handle_event("create_tip" = event, %{"tip_form" => params} = unsigned_params, socket) do
    changeset =
      %TipForm{}
      |> TipForm.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      if socket.assigns[:current_user] do
        with {:ok, token} <- Accounts.get_access_token(socket.assigns.current_user),
             {:ok, recipient} <- Workspace.ensure_user(token, get_field(changeset, :github_handle)),
             {:ok, checkout_url} <-
               Bounties.create_tip(%{
                 creator: socket.assigns.current_user,
                 owner: socket.assigns.current_user,
                 recipient: recipient,
                 amount: get_field(changeset, :amount)
               }) do
          {:noreply, redirect(socket, external: checkout_url)}
        else
          {:error, reason} ->
            Logger.error("Failed to create tip: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Something went wrong")}
        end
      else
        {:noreply,
         socket
         |> assign(:pending_action, {event, unsigned_params})
         |> push_event("open_popup", %{url: socket.assigns.oauth_url})}
      end
    else
      {:noreply, assign(socket, :tip_form, to_form(changeset))}
    end
  end

  def handle_info({:authenticated, user}, socket) do
    socket = assign(socket, :current_user, user)

    case socket.assigns.pending_action do
      {event, params} ->
        socket = assign(socket, :pending_action, nil)
        handle_event(event, params, socket)

      nil ->
        {:noreply, socket}
    end
  end

  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_bounties(socket)}
  end

  defp assign_bounties(socket) do
    bounties =
      Bounties.list_bounties(
        status: :open,
        tech_stack: ["Swift"],
        limit: 100
      )

    assign(socket, :bounties, bounties)
  end

  defp assign_active_repos(socket) do
    active_pollers =
      Enum.reduce(Algora.Github.Poller.Supervisor.which_children(), [], fn {_, pid, _, _}, acc ->
        {owner, name} = GenServer.call(pid, :get_repo_info)

        case Algora.Github.Poller.Supervisor.find_child(owner, name) do
          {_, pid, _, _} ->
            if GenServer.call(pid, :is_paused) do
              acc
            else
              [{owner, name} | acc]
            end

          _ ->
            acc
        end
      end)

    # Build dynamic OR conditions for each owner/name pair
    conditions =
      Enum.reduce(active_pollers, false, fn {owner, name}, acc_query ->
        if acc_query do
          dynamic([r, u], ^acc_query or (u.provider_login == ^owner and r.name == ^name))
        else
          dynamic([r, u], u.provider_login == ^owner and r.name == ^name)
        end
      end)

    repos =
      Repo.all(
        from(r in Algora.Workspace.Repository,
          join: u in assoc(r, :user),
          where: r.provider == "github",
          where: ^conditions,
          preload: [user: u],
          order_by: [asc: r.inserted_at]
        )
      )

    assign(socket, :repos, repos)
  end
end
