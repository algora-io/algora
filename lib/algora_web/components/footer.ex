defmodule AlgoraWeb.Components.Footer do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.Constants

  def footer(assigns) do
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
                    href="https://console.algora.io/community"
                  >
                    Community
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
