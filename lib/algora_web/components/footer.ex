defmodule AlgoraWeb.Components.Footer do
  @moduledoc false
  use AlgoraWeb.Component
  use AlgoraWeb, :verified_routes

  import AlgoraWeb.CoreComponents

  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.Constants

  def footer(assigns) do
    ~H"""
    <footer aria-labelledby="footer-heading">
      <h2 id="footer-heading" class="sr-only">Footer</h2>
      <div class="mx-auto max-w-7xl px-6 pb-8 lg:px-8">
        <%!-- <div class="border-t border-white/10 pt-16 sm:pt-24">
          <div class="grid grid-cols-2 gap-x-12 gap-y-20 md:grid-cols-4">
            <div>
              <h3 class="text-base font-semibold leading-6 text-white">
                <.link navigate={~p"/bounties"}>Bounties</.link>
              </h3>
              <ul role="list" class="mt-6 space-y-4">
                <li>
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/bounties/rust"}
                  >
                    Rust
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/bounties/typescript"}
                  >
                    TypeScript
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/bounties/scala"}
                  >
                    Scala
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/bounties/c,c++"}
                  >
                    C / C++
                  </.link>
                </li>
              </ul>
            </div>
            <div>
              <h3 class="text-base font-semibold leading-6 text-white">Community</h3>
              <ul role="list" class="mt-6 space-y-4">
                <li>
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/projects"}
                  >
                    Projects
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/community"}
                  >
                    Community
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/leaderboard"}
                  >
                    Leaderboard
                  </.link>
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
                    Docs
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
        </div> --%>
        <div class={
          classes([
            "pt-8 border-t border-white/10 flex flex-col md:flex-row md:justify-between md:items-start gap-8"
            # "mt-16 sm:mt-20 lg:mt-24"
          ])
        }>
          <div class="flex gap-3 sm:gap-6 md:order-2">
            <.link
              class="rounded-xl border-2 border-gray-500 p-2 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href={Constants.get(:discord_url)}
              rel="noopener"
              target="_blank"
            >
              <span class="sr-only">Discord</span>
              <.icon name="tabler-brand-discord-filled" class="h-6 w-6 sm:h-8 sm:w-8" />
            </.link>
            <.link
              class="rounded-xl border-2 border-gray-500 p-2 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href={Constants.get(:twitter_url)}
              rel="noopener"
              target="_blank"
            >
              <span class="sr-only">X (formerly Twitter)</span>
              <.icon name="tabler-brand-x" class="h-6 w-6 sm:h-8 sm:w-8" />
            </.link>
            <.link
              class="rounded-xl border-2 border-gray-500 p-2 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href={Constants.get(:github_url)}
              rel="noopener"
              target="_blank"
            >
              <span class="sr-only">GitHub</span>
              <Logos.github class="h-6 w-6 sm:h-8 sm:w-8" />
            </.link>
            <.link
              class="rounded-xl border-2 border-gray-500 p-2 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href={Constants.get(:linkedin_url)}
              rel="noopener"
              target="_blank"
            >
              <span class="sr-only">LinkedIn</span>
              <.icon name="tabler-brand-linkedin" class="h-6 w-6 sm:h-8 sm:w-8" />
            </.link>
            <.link
              class="rounded-xl border-2 border-gray-500 p-2 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href={Constants.get(:youtube_url)}
              rel="noopener"
              target="_blank"
            >
              <span class="sr-only">YouTube</span>
              <.icon name="tabler-brand-youtube-filled" class="h-6 w-6 sm:h-8 sm:w-8" />
            </.link>
            <.link
              class="rounded-xl border-2 border-gray-500 p-2 text-gray-400 transition-colors hover:border-gray-400 hover:text-gray-300 sm:p-3"
              href={"mailto:" <> Constants.get(:email)}
            >
              <span class="sr-only">Email</span>
              <.icon name="tabler-mail-filled" class="h-6 w-6 sm:h-8 sm:w-8" />
            </.link>
          </div>

          <div class="flex flex-col gap-4 md:gap-2">
            <div class="text-sm font-medium leading-5 text-gray-400 md:text-base">
              © {Date.utc_today().year} Algora, Public Benefit Corporation
            </div>

            <div class="flex flex-col gap-2">
              <.link
                class="flex w-max items-center gap-2 rounded-full border border-gray-700 py-2 pl-2 pr-3.5 text-xs text-muted-foreground hover:text-foreground transition-colors hover:border-gray-600"
                href={"tel:" <> Constants.get(:tel)}
              >
                <.icon name="tabler-phone-filled" class="size-4" /> Call us
                <span>{Constants.get(:tel_formatted)}</span>
              </.link>
            </div>
          </div>
        </div>
      </div>
    </footer>
    """
  end
end
