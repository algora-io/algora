defmodule AlgoraWeb.SwiftBountiesLive do
  use AlgoraWeb, :live_view
  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.Constants

  def mount(_params, _session, socket) do
    # Hardcoded data for demonstration
    active_bounties = [
      %{
        project: "Swift NIO",
        title: "Memory leak in HTTP2 handler",
        amount: Money.new(2400, :USD),
        backers: 6
      },
      %{
        project: "Swift Collections",
        title: "Add B-tree implementation",
        amount: Money.new(1800, :USD),
        backers: 4
      },
      %{
        project: "Swift Crypto",
        title: "ECDSA signing performance",
        amount: Money.new(900, :USD),
        backers: 2
      }
    ]

    recent_activity = [
      %{
        type: :tip,
        from: "@sarah",
        to: "@dave",
        amount: Money.new(50, :USD),
        description: "fixing Swift Package Manager tests"
      },
      %{
        type: :bounty,
        from: "@company123",
        amount: Money.new(500, :USD),
        description: "Swift DocC improvements"
      },
      %{
        type: :contribution,
        from: "@swift_fan",
        amount: Money.new(100, :USD),
        description: "SwiftUI navigation bounty"
      }
    ]

    {:ok,
     socket
     |> assign(:page_title, "Swift Bounties")
     |> assign(:active_bounties, active_bounties)
     |> assign(:recent_activity, recent_activity)}
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
      <div class="mx-auto max-w-7xl px-6 pb-24 pt-10 sm:pb-32 lg:flex lg:px-8 lg:py-40">
        <div class="mx-auto max-w-2xl shrink-0 lg:mx-0 lg:pt-8">
          <.wordmark />
          <h1 class="mt-10 text-pretty text-5xl font-semibold tracking-tight text-white sm:text-7xl">
            Swift Bounties
          </h1>
          <p class="mt-8 text-pretty text-lg font-medium text-gray-400 sm:text-xl/8">
            The Swift ecosystem needs sustainable funding for "middle ring" infrastructure - projects that are too niche for Apple but too broad for a single company.
          </p>
          <div class="mt-10 flex items-center gap-x-6">
            <.button size="lg">Create Bounty</.button>
          </div>
        </div>
        <div class="mx-auto mt-16 flex max-w-2xl sm:mt-24 lg:ml-10 lg:mr-0 lg:mt-0 lg:max-w-none lg:flex-none xl:ml-32">
          <div class="max-w-3xl flex-none sm:max-w-5xl lg:max-w-none">
            <.card class="bg-card/25">
              <.card_header>
                <.card_title>How It Works</.card_title>
              </.card_header>
              <.card_content>
                <div class="space-y-6">
                  <div class="space-y-2">
                    <.icon name="tabler-diamond" class="h-8 w-8 text-primary" />
                    <h3 class="font-semibold">Post Bounties</h3>
                    <p class="text-sm text-muted-foreground">
                      Anyone can post bounties on any issue in any Swift repository
                    </p>
                  </div>
                  <div class="space-y-2">
                    <.icon name="tabler-users" class="h-8 w-8 text-primary" />
                    <h3 class="font-semibold">Pool Funds</h3>
                    <p class="text-sm text-muted-foreground">
                      Multiple people can contribute to the same bounty
                    </p>
                  </div>
                  <div class="space-y-2">
                    <.icon name="tabler-coin" class="h-8 w-8 text-primary" />
                    <h3 class="font-semibold">Reward Contributors</h3>
                    <p class="text-sm text-muted-foreground">
                      Pay only when the issue is resolved
                    </p>
                  </div>
                </div>
              </.card_content>
            </.card>
          </div>
        </div>
      </div>
    </div>

    <div class="container max-w-7xl mx-auto px-6 space-y-12">
      <.card>
        <.card_header class="flex justify-between">
          <.card_title>Active Bounties</.card_title>
        </.card_header>
        <.card_content>
          <div class="-mx-6 overflow-x-auto">
            <table class="w-full">
              <thead>
                <tr class="border-b">
                  <th class="px-6 py-3 text-left text-sm font-medium">Project</th>
                  <th class="px-6 py-3 text-left text-sm font-medium">Issue</th>
                  <th class="px-6 py-3 text-left text-sm font-medium">Amount</th>
                  <th class="px-6 py-3 text-left text-sm font-medium">Contributors</th>
                </tr>
              </thead>
              <tbody>
                <%= for bounty <- @active_bounties do %>
                  <tr class="border-b hover:bg-muted/50">
                    <td class="px-6 py-4 text-sm">{bounty.project}</td>
                    <td class="px-6 py-4 text-sm">{bounty.title}</td>
                    <td class="px-6 py-4 text-sm font-semibold text-success">
                      {Money.to_string!(bounty.amount)}
                    </td>
                    <td class="px-6 py-4 text-sm">{bounty.backers} backers</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
          <div class="pt-4 flex justify-center">
            <.button variant="ghost" phx-click="load_more">
              <.icon name="tabler-arrow-down" class="w-4 h-4 mr-2" /> Load More
            </.button>
          </div>
        </.card_content>
      </.card>

      <.card>
        <.card_header>
          <.card_title>Recent Activity</.card_title>
        </.card_header>
        <.card_content>
          <div class="space-y-4">
            <%= for activity <- @recent_activity do %>
              <div class="flex items-center gap-4">
                <div class="h-9 w-9 rounded-full bg-primary/10 flex items-center justify-center">
                  <.icon
                    name={
                      case activity.type do
                        :tip -> "tabler-coin"
                        :bounty -> "tabler-gift"
                        :contribution -> "tabler-plus"
                      end
                    }
                    class="h-5 w-5 text-primary"
                  />
                </div>
                <div class="flex-1">
                  <p class="text-sm">
                    <span class="font-medium">{activity.from}</span>
                    <%= case activity.type do %>
                      <% :tip -> %>
                        tipped <span class="font-medium">{activity.to}</span>
                        <span class="font-medium text-success">
                          {Money.to_string!(activity.amount)}
                        </span>
                        for {activity.description}
                      <% :bounty -> %>
                        posted
                        <span class="font-medium text-success">
                          {Money.to_string!(activity.amount)}
                        </span>
                        bounty for {activity.description}
                      <% :contribution -> %>
                        added
                        <span class="font-medium text-success">
                          {Money.to_string!(activity.amount)}
                        </span>
                        to existing {activity.description}
                    <% end %>
                  </p>
                </div>
              </div>
            <% end %>
          </div>
        </.card_content>
      </.card>
    </div>

    <div class="relative">
      <.footer />
    </div>
    """
  end

  defp footer(assigns) do
    ~H"""
    <footer aria-labelledby="footer-heading">
      <h2 id="footer-heading" class="sr-only">Footer</h2>
      <div class="mx-auto max-w-7xl px-6 pb-8 lg:px-8">
        <div class="border-t border-white/10 pt-16 sm:pt-24">
          <div class="grid grid-cols-2 gap-x-12 gap-y-20 md:grid-cols-4">
            <div>
              <h3 class="text-base font-semibold leading-6 text-white">
                <a href="https://console.algora.io/bounties">Bounties</a>
              </h3>
              <ul role="list" class="mt-6 space-y-4">
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/bounties/t/rust"
                  >
                    Rust
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/bounties/t/typescript"
                  >
                    TypeScript
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/bounties/t/scala"
                  >
                    Scala
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/bounties/t/go"
                  >
                    Go
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/bounties/t/swift"
                  >
                    Swift
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h3 class="text-base font-semibold leading-6 text-white">Community</h3>
              <ul role="list" class="mt-6 space-y-4">
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/events"
                  >
                    Activity
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/home/projects#content"
                  >
                    Projects
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/experts"
                  >
                    Experts
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/home/leaderboard#content"
                  >
                    Leaderboard
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href={Constants.get(:youtube_url)}
                  >
                    Open Source Founder Podcast
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h3 class="text-base font-semibold leading-6 text-white">Resources</h3>
              <ul role="list" class="mt-6 space-y-4">
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href={Constants.get(:demo_url)}
                  >
                    Demo
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href={Constants.get(:docs_url)}
                  >
                    Documentation
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href={Constants.get(:sdk_url)}
                  >
                    SDK
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/pricing"
                  >
                    Pricing
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h3 class="text-base font-semibold leading-6 text-white">Company</h3>
              <ul role="list" class="mt-6 space-y-4">
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href={Constants.get(:privacy_url)}
                  >
                    Privacy
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href={Constants.get(:terms_url)}
                  >
                    Terms
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href={Constants.get(:blog_url)}
                  >
                    Blog
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href={Constants.get(:contact_url)}
                  >
                    Talk to founders
                  </a>
                </li>
              </ul>
            </div>
          </div>
        </div>
        <div class="mt-16 border-t border-white/10 pt-8 sm:mt-20 md:flex md:justify-between lg:mt-24">
          <div class="flex gap-4 sm:gap-6 md:order-2">
            <a
              class="rounded-xl border-2 border-gray-500 p-3 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href={Constants.get(:discord_url)}
            >
              <span class="sr-only">Discord</span>
              <.icon name="tabler-brand-discord-filled" class="h-6 w-6 sm:h-8 sm:w-8" />
            </a>
            <a
              class="rounded-xl border-2 border-gray-500 p-3 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href={Constants.get(:twitter_url)}
            >
              <span class="sr-only">X (formerly Twitter)</span>
              <.icon name="tabler-brand-x" class="h-6 w-6 sm:h-8 sm:w-8" />
            </a>
            <a
              class="rounded-xl border-2 border-gray-500 p-3 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href={Constants.get(:github_url)}
            >
              <span class="sr-only">GitHub</span>
              <Logos.github class="h-6 w-6 sm:h-8 sm:w-8" />
            </a>
            <a
              class="rounded-xl border-2 border-gray-500 p-3 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href={Constants.get(:youtube_url)}
            >
              <span class="sr-only">YouTube</span>
              <.icon name="tabler-brand-youtube-filled" class="h-6 w-6 sm:h-8 sm:w-8" />
            </a>
            <a
              class="rounded-xl border-2 border-gray-500 p-3 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href={"mailto:" <> Constants.get(:email)}
            >
              <span class="sr-only">Email</span>
              <.icon name="tabler-mail-filled" class="h-6 w-6 sm:h-8 sm:w-8" />
            </a>
          </div>
          <p class="mt-8 text-sm font-medium leading-5 text-gray-400 md:order-1 md:mt-0 md:text-base">
            © {Date.utc_today().year} Algora, Public Benefit Corporation
          </p>
        </div>
      </div>
    </footer>
    """
  end
end
