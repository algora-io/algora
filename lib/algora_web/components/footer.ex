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
        <div class="border-t border-white/10 pt-16 sm:pt-24">
          <div class="grid grid-cols-2 gap-x-12 gap-y-20 md:grid-cols-4">
            <div>
              <h3 class="text-base font-semibold leading-6 text-white">
                <.link navigate={~p"/bounties"}>Bounties</.link>
              </h3>
              <ul role="list" class="mt-6 space-y-4">
                <li>
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/bounties?#{%{tech: "rust"}}"}
                  >
                    Rust
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/bounties?#{%{tech: "typescript"}}"}
                  >
                    TypeScript
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/bounties?#{%{tech: "scala"}}"}
                  >
                    Scala
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/bounties?#{%{tech: "c,c++"}}"}
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
                  <.link
                    class="text-base font-medium leading-6 text-gray-400 hover:text-white"
                    navigate={~p"/pricing"}
                  >
                    Pricing
                  </.link>
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

        <div class="mt-8 sm:mt-10 md:flex md:justify-between lg:mt-12">
          <div class="relative rounded-2xl bg-black/25 p-8 lg:p-12 ring-1 ring-emerald-500/20 transition-colors backdrop-blur-sm">
            <div class="grid items-center lg:grid-cols-7 gap-4 h-full">
              <div class="col-span-4 text-base leading-6">
                <h3 class="col-span-3 text-3xl font-semibold text-foreground">
                  Tip any contributor
                  <span class="text-emerald-500 drop-shadow-[0_1px_5px_#34d39980]">in seconds</span>
                </h3>
                <p class="mt-4 text-lg font-medium text-muted-foreground">
                  Support the maintainers behind your favorite open source projects
                </p>
                <div class="mt-6 space-y-3">
                  <div class="flex items-center gap-2 text-sm text-muted-foreground">
                    <.icon name="tabler-check" class="h-5 w-5 text-emerald-400 flex-none" />
                    <span>Send tips directly to GitHub usernames</span>
                  </div>
                  <div class="flex items-center gap-2 text-sm text-muted-foreground">
                    <.icon name="tabler-check" class="h-5 w-5 text-emerald-400 flex-none" />
                    <span>No GitHub account required for the recipient</span>
                  </div>
                  <div class="flex items-center gap-2 text-sm text-muted-foreground">
                    <.icon name="tabler-check" class="h-5 w-5 text-emerald-400 flex-none" />
                    <span>Algora handles payouts, compliance & 1099s</span>
                  </div>
                </div>
              </div>

              <.form for={@tip_form} phx-submit="create_tip" class="col-span-3 space-y-6">
                <div class="grid lg:grid-cols-2 gap-y-6 gap-x-3">
                  <.input
                    label="GitHub Username"
                    field={@tip_form[:github_handle]}
                    placeholder="jsmith"
                  />
                  <.input
                    label="Amount"
                    icon="tabler-currency-dollar"
                    field={@tip_form[:amount]}
                    class="placeholder:text-emerald-500"
                  />
                </div>
                <.input
                  label="URL"
                  field={@tip_form[:url]}
                  placeholder="https://github.com/owner/repo/issues/123"
                  helptext="We'll comment to notify the developer."
                />
                <div class="flex flex-col gap-2">
                  <.button size="lg" class="w-full drop-shadow-[0_1px_5px_#34d39980]">
                    Tip contributor
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        </div>

        <div class="mt-8 sm:mt-10 md:flex md:justify-between lg:mt-12">
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
