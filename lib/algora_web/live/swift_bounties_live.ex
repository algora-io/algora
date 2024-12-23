defmodule AlgoraWeb.SwiftBountiesLive do
  use AlgoraWeb, :live_view

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
            <.button size="lg" variant="outline">View Bounties</.button>
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
                    <.icon name="tabler-git-pull-request" class="h-8 w-8 text-primary" />
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
                    <h3 class="font-semibold">Pay Out</h3>
                    <p class="text-sm text-muted-foreground">
                      Pay only when the work is completed and merged
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
                    href="https://console.algora.io/bounties/t/c++"
                  >
                    C++
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
                    href="https://www.youtube.com/@algora-io"
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
                    href="https://www.youtube.com/watch?v=Ts5GhlEROrs"
                  >
                    Demo
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://docs.algora.io"
                  >
                    Documentation
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/sdk"
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
                    href="https://console.algora.io/legal/privacy"
                  >
                    Privacy
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://console.algora.io/legal/terms"
                  >
                    Terms
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://blog.algora.io"
                  >
                    Blog
                  </a>
                </li>
                <li>
                  <a
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    href="https://docs.algora.io/contact"
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
              href="https://algora.io/discord"
            >
              <span class="sr-only">Discord</span><svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="h-6 w-6 sm:h-8 sm:w-8"
                aria-hidden="true"
              ><path
                d="M14.983 3l.123 .006c2.014 .214 3.527 .672 4.966 1.673a1 1 0 0 1 .371 .488c1.876 5.315 2.373 9.987 1.451 12.28c-1.003 2.005 -2.606 3.553 -4.394 3.553c-.732 0 -1.693 -.968 -2.328 -2.045a21.512 21.512 0 0 0 2.103 -.493a1 1 0 1 0 -.55 -1.924c-3.32 .95 -6.13 .95 -9.45 0a1 1 0 0 0 -.55 1.924c.717 .204 1.416 .37 2.103 .494c-.635 1.075 -1.596 2.044 -2.328 2.044c-1.788 0 -3.391 -1.548 -4.428 -3.629c-.888 -2.217 -.39 -6.89 1.485 -12.204a1 1 0 0 1 .371 -.488c1.439 -1.001 2.952 -1.459 4.966 -1.673a1 1 0 0 1 .935 .435l.063 .107l.651 1.285l.137 -.016a12.97 12.97 0 0 1 2.643 0l.134 .016l.65 -1.284a1 1 0 0 1 .754 -.54l.122 -.009zm-5.983 7a2 2 0 0 0 -1.977 1.697l-.018 .154l-.005 .149l.005 .15a2 2 0 1 0 1.995 -2.15zm6 0a2 2 0 0 0 -1.977 1.697l-.018 .154l-.005 .149l.005 .15a2 2 0 1 0 1.995 -2.15z"
                fill="currentColor"
                stroke-width="0"
              ></path></svg>
            </a>
            <a
              class="rounded-xl border-2 border-gray-500 p-3 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href="https://twitter.com/algoraio"
            >
              <span class="sr-only">Twitter</span><svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="h-6 w-6 sm:h-8 sm:w-8"
                aria-hidden="true"
              ><path d="M4 4l11.733 16h4.267l-11.733 -16z"></path><path d="M4 20l6.768 -6.768m2.46 -2.46l6.772 -6.772"></path></svg>
            </a>
            <a
              class="rounded-xl border-2 border-gray-500 p-3 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href="https://github.com/algora-io"
            >
              <span class="sr-only">GitHub</span><svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="h-6 w-6 sm:h-8 sm:w-8"
                aria-hidden="true"
              ><path
                d="M5.315 2.1c.791 -.113 1.9 .145 3.333 .966l.272 .161l.16 .1l.397 -.083a13.3 13.3 0 0 1 4.59 -.08l.456 .08l.396 .083l.161 -.1c1.385 -.84 2.487 -1.17 3.322 -1.148l.164 .008l.147 .017l.076 .014l.05 .011l.144 .047a1 1 0 0 1 .53 .514a5.2 5.2 0 0 1 .397 2.91l-.047 .267l-.046 .196l.123 .163c.574 .795 .93 1.728 1.03 2.707l.023 .295l.007 .272c0 3.855 -1.659 5.883 -4.644 6.68l-.245 .061l-.132 .029l.014 .161l.008 .157l.004 .365l-.002 .213l-.003 3.834a1 1 0 0 1 -.883 .993l-.117 .007h-6a1 1 0 0 1 -.993 -.883l-.007 -.117v-.734c-1.818 .26 -3.03 -.424 -4.11 -1.878l-.535 -.766c-.28 -.396 -.455 -.579 -.589 -.644l-.048 -.019a1 1 0 0 1 .564 -1.918c.642 .188 1.074 .568 1.57 1.239l.538 .769c.76 1.079 1.36 1.459 2.609 1.191l.001 -.678l-.018 -.168a5.03 5.03 0 0 1 -.021 -.824l.017 -.185l.019 -.12l-.108 -.024c-2.976 -.71 -4.703 -2.573 -4.875 -6.139l-.01 -.31l-.004 -.292a5.6 5.6 0 0 1 .908 -3.051l.152 -.222l.122 -.163l-.045 -.196a5.2 5.2 0 0 1 .145 -2.642l.1 -.282l.106 -.253a1 1 0 0 1 .529 -.514l.144 -.047l.154 -.03z"
                fill="currentColor"
                stroke-width="0"
              ></path></svg>
            </a>
            <a
              class="rounded-xl border-2 border-gray-500 p-3 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href="https://www.youtube.com/@algora-io"
            >
              <span class="sr-only">YouTube</span><svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="h-6 w-6 sm:h-8 sm:w-8"
                aria-hidden="true"
              ><path
                d="M18 3a5 5 0 0 1 5 5v8a5 5 0 0 1 -5 5h-12a5 5 0 0 1 -5 -5v-8a5 5 0 0 1 5 -5zm-9 6v6a1 1 0 0 0 1.514 .857l5 -3a1 1 0 0 0 0 -1.714l-5 -3a1 1 0 0 0 -1.514 .857z"
                fill="currentColor"
                stroke-width="0"
              ></path></svg>
            </a>
            <a
              class="rounded-xl border-2 border-gray-500 p-3 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href="mailto:info@algora.io"
            >
              <span class="sr-only">Email</span><svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="h-6 w-6 sm:h-8 sm:w-8"
                aria-hidden="true"
              ><path
                d="M22 7.535v9.465a3 3 0 0 1 -2.824 2.995l-.176 .005h-14a3 3 0 0 1 -2.995 -2.824l-.005 -.176v-9.465l9.445 6.297l.116 .066a1 1 0 0 0 .878 0l.116 -.066l9.445 -6.297z"
                fill="currentColor"
                stroke-width="0"
              ></path><path
                d="M19 4c1.08 0 2.027 .57 2.555 1.427l-9.555 6.37l-9.555 -6.37a2.999 2.999 0 0 1 2.354 -1.42l.201 -.007h14z"
                fill="currentColor"
                stroke-width="0"
              ></path></svg>
            </a>
          </div>
          <p class="mt-8 text-sm font-medium leading-5 text-gray-400 md:order-1 md:mt-0 md:text-base">
            © 2024 Algora, Public Benefit Corporation
          </p>
        </div>
      </div>
    </footer>
    """
  end
end
