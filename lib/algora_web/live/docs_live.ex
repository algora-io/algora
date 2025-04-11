defmodule AlgoraWeb.DocsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  defp nav do
    [
      %{
        title: 'Overview',
        links: [
          %{title: 'Introduction', href: ~p"/docs"}
        ]
      },
      %{
        title: 'GitHub bounties',
        links: [
          %{title: 'In your own repos', href: ~p"/docs/bounties/in-your-own-repos"},
          %{title: 'In other projects', href: ~p"/docs/bounties/in-other-projects"}
        ]
      },
      %{
        title: 'Algora bounties',
        links: [
          %{title: 'Exclusive', href: ~p"/docs/bounties/exclusive"},
          %{title: 'Custom', href: ~p"/docs/bounties/custom"}
        ]
      },
      %{
        title: 'Tips',
        links: [
          %{title: 'Share on GitHub', href: ~p"/docs/tips/share-github"},
          %{title: 'Share on contributors table', href: ~p"/docs/tips/share-contributors"}
        ]
      },
      %{
        title: 'Contracts',
        links: [
          %{title: 'Share on contributors table', href: ~p"/docs/contracts/share-contributors"}
        ]
      },
      %{
        title: 'Marketplace',
        links: [
          %{title: 'Share with Algora matches', href: ~p"/docs/marketplace/share-matches"}
        ]
      },
      %{
        title: 'Org workspace',
        links: [
          %{title: 'Share public board', href: ~p"/docs/workspace/public-board"},
          %{title: 'View leaderboard', href: ~p"/docs/workspace/leaderboard"},
          %{title: 'View transactions', href: ~p"/docs/workspace/transactions"},
          %{title: 'Set up autopay', href: ~p"/docs/workspace/autopay"},
          %{title: 'Customize bot message', href: ~p"/docs/workspace/bot-message"}
        ]
      },
      %{
        title: 'Embed',
        links: [
          %{title: 'SDK', href: ~p"/docs/embed/sdk"},
          %{title: 'Shields', href: ~p"/docs/embed/shields"},
          %{title: 'OG images', href: ~p"/docs/embed/og-images"}
        ]
      }
    ]
  end

  @impl true
  def mount(%{"path" => []}, _session, socket) do
    docs = Algora.Content.list_content_rec("docs")
    {:ok, assign(socket, docs: docs, page_title: "Docs")}
  end

  @impl true
  def mount(%{"path" => path}, _session, socket) do
    dbg(path)
    slug = List.last(path)
    dir = Path.join("docs", Enum.drop(path, -1))

    case Algora.Content.load_content(dir, slug) do
      {:ok, content} ->
        {:ok, assign(socket, content: content, page_title: content.title)}

      {:error, _reason} ->
        {:ok, push_navigate(socket, to: ~p"/docs")}
    end
  end

  defp render_navigation_section(assigns) do
    ~H"""
    <li :for={section <- nav()} class="relative mt-6">
      <h2 class="text-xs font-semibold text-gray-900 dark:text-white">
        {section.title}
      </h2>
      <div class="relative mt-3 pl-2">
        <div class="absolute inset-y-0 left-2 w-px bg-gray-900/10 dark:bg-white/5"></div>
        <ul role="list" class="border-l border-transparent">
          <%= for link <- section.links do %>
            <li class="relative">
              <.link
                href={link.href}
                class="flex justify-between gap-2 py-1 pr-3 text-sm transition pl-4 text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white"
              >
                <span class="truncate">{link.title}</span>
              </.link>
            </li>
          <% end %>
        </ul>
      </div>
    </li>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-black lg:ml-72 xl:ml-80">
      <header class="bg-black fixed inset-y-0 left-0 z-40 contents w-72 overflow-y-auto scrollbar-thin border-r border-gray-900/10 px-6 pt-4 pb-8 dark:border-white/10 lg:block xl:w-80">
        <div class="hidden lg:flex">
          <.wordmark class="h-8 w-auto text-foreground" />
        </div>
        <div
          class="fixed inset-x-0 top-0 z-50 flex h-14 items-center justify-between gap-5 px-4 transition sm:px-6 lg:z-30 lg:px-8 backdrop-blur-sm dark:backdrop-blur lg:left-72 xl:left-80 bg-white/[var(--bg-opacity-light)] dark:bg-gray-900/[var(--bg-opacity-dark)]"
          style="--bg-opacity-light: 0.5; --bg-opacity-dark: 0.2;"
        >
          <div class="absolute inset-x-0 top-full h-px transition bg-gray-900/7.5 dark:bg-white/7.5">
          </div>
          <div class="hidden md:block"></div>
          <div class="flex w-full items-center justify-between gap-5 lg:hidden">
            <.wordmark class="h-6 w-auto text-foreground" />
            <button
              type="button"
              class="flex items-center justify-center rounded-md transition hover:bg-gray-900/5 dark:hover:bg-white/5"
              aria-label="Toggle navigation"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="h-5 w-5 stroke-gray-900 dark:stroke-white"
              >
                <path d="M4 8l16 0"></path>
                <path d="M4 16l16 0"></path>
              </svg>
            </button>
          </div>
          <div class="flex items-center gap-5">
            <nav class="hidden md:block">
              <ul role="list" class="flex items-center gap-8">
                <li>
                  <a
                    class="text-sm leading-5 text-gray-600 transition hover:text-gray-900 dark:text-gray-400 dark:hover:text-white"
                    href="/docs/contact"
                  >
                    Contact
                  </a>
                </li>
              </ul>
            </nav>
            <div class="hidden md:block md:h-5 md:w-px md:bg-gray-900/10 md:dark:bg-white/15"></div>
            <div class="hidden whitespace-nowrap md:contents">
              <a
                class="inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition rounded-full bg-gray-900 py-1 px-3 text-white hover:bg-gray-700 dark:bg-emerald-400/10 dark:text-emerald-400 dark:ring-1 dark:ring-inset dark:ring-emerald-400/20 dark:hover:bg-emerald-400/10 dark:hover:text-emerald-300 dark:hover:ring-emerald-300"
                href="/"
              >
                Get started
              </a>
            </div>
          </div>
        </div>
        <nav class="hidden lg:mt-10 lg:block">
          <ul role="list">
            <li class="md:hidden">
              <a
                class="block py-1 text-sm text-gray-600 transition hover:text-gray-900 dark:text-gray-400 dark:hover:text-white"
                href="https://docs.algora.io"
              >
                Documentation
              </a>
            </li>
            <li class="md:hidden">
              <a
                class="block py-1 text-sm text-gray-600 transition hover:text-gray-900 dark:text-gray-400 dark:hover:text-white"
                href="mailto:info@algora.io"
              >
                Contact
              </a>
            </li>
            {render_navigation_section(assigns)}
            <li class="sticky bottom-0 z-10 mt-6 md:hidden">
              <a
                class="inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition rounded-full bg-gray-900 py-1 px-3 text-white hover:bg-gray-700 dark:bg-emerald-500 dark:text-white dark:hover:bg-emerald-400 w-full"
                href="/"
              >
                Get started
              </a>
            </li>
          </ul>
        </nav>
      </header>
      <div class="h-full relative px-4 pt-14 sm:px-6 lg:px-8">
        <main class="py-16">
          <article class="prose dark:prose-invert max-w-5xl min-h-[calc(100svh-17rem)]">
            <div class="absolute inset-0 mx-0 max-w-none overflow-hidden">
              <div class="absolute left-1/2 top-0 ml-[-38rem] h-[25rem] w-[81.25rem] dark:[mask-image:linear-gradient(white,transparent)]">
                <div class="absolute inset-0 bg-gradient-to-r from-[#36b49f] to-[#DBFF75] opacity-40 [mask-image:radial-gradient(farthest-side_at_top,white,transparent)] dark:from-[#36b49f]/30 dark:to-[#DBFF75]/30 dark:opacity-100">
                  <svg
                    aria-hidden="true"
                    class="absolute inset-x-0 inset-y-[-50%] h-[200%] w-full skew-y-[-18deg] fill-black/40 stroke-black/50 mix-blend-overlay dark:fill-white/2.5 dark:stroke-white/5"
                  >
                    <defs>
                      <pattern
                        id=":r4q:"
                        width="72"
                        height="56"
                        patternUnits="userSpaceOnUse"
                        x="-12"
                        y="4"
                      >
                        <path d="M.5 56V.5H72" fill="none"></path>
                      </pattern>
                    </defs>
                    <rect width="100%" height="100%" stroke-width="0" fill="url(#:r4q:)"></rect>
                    <svg x="-12" y="4" class="overflow-visible">
                      <rect stroke-width="0" width="73" height="57" x="288" y="168"></rect>
                      <rect stroke-width="0" width="73" height="57" x="144" y="56"></rect>
                      <rect stroke-width="0" width="73" height="57" x="504" y="168"></rect>
                      <rect stroke-width="0" width="73" height="57" x="720" y="336"></rect>
                    </svg>
                  </svg>
                </div>
                <svg
                  viewBox="0 0 1113 440"
                  aria-hidden="true"
                  class="absolute top-0 left-1/2 ml-[-19rem] w-[69.5625rem] fill-white blur-[26px] dark:hidden"
                >
                  <path d="M.016 439.5s-9.5-300 434-300S882.516 20 882.516 20V0h230.004v439.5H.016Z">
                  </path>
                </svg>
              </div>
            </div>
            <%= if assigns[:content] do %>
              {raw(@content.content)}
            <% else %>
              <.overview />
            <% end %>
          </article>
        </main>
        <footer class="max-w-2xl space-y-10 pb-8 lg:max-w-5xl">
          <div class="flex flex-col items-center justify-between gap-5 border-t border-gray-900/5 pt-8 dark:border-white/5 sm:flex-row">
            <p class="text-xs text-gray-600 dark:text-gray-400">
              © {DateTime.utc_now().year} Algora, Public Benefit Corporation
            </p>
            <div class="flex gap-4">
              <.link
                class="group"
                href={AlgoraWeb.Constants.get(:twitter_url)}
                rel="noopener"
                target="_blank"
              >
                <span class="sr-only">Follow us on Twitter</span><svg
                  viewBox="0 0 20 20"
                  aria-hidden="true"
                  class="h-5 w-5 fill-gray-700 transition group-hover:fill-gray-900 dark:group-hover:fill-gray-500"
                ><path d="M16.712 6.652c.01.146.01.29.01.436 0 4.449-3.267 9.579-9.242 9.579v-.003a8.963 8.963 0 0 1-4.98-1.509 6.379 6.379 0 0 0 4.807-1.396c-1.39-.027-2.608-.966-3.035-2.337.487.097.99.077 1.467-.059-1.514-.316-2.606-1.696-2.606-3.3v-.041c.45.26.956.404 1.475.42C3.18 7.454 2.74 5.486 3.602 3.947c1.65 2.104 4.083 3.382 6.695 3.517a3.446 3.446 0 0 1 .94-3.217 3.172 3.172 0 0 1 4.596.148 6.38 6.38 0 0 0 2.063-.817 3.357 3.357 0 0 1-1.428 1.861 6.283 6.283 0 0 0 1.865-.53 6.735 6.735 0 0 1-1.62 1.744Z"></path></svg>
              </.link>
              <.link
                class="group"
                href={AlgoraWeb.Constants.get(:discord_url)}
                rel="noopener"
                target="_blank"
              >
                <span class="sr-only">Join our Discord server</span><svg
                  viewBox="0 0 20 20"
                  aria-hidden="true"
                  class="h-5 w-5 fill-gray-700 transition group-hover:fill-gray-900 dark:group-hover:fill-gray-500"
                ><path d="M16.238 4.515a14.842 14.842 0 0 0-3.664-1.136.055.055 0 0 0-.059.027 10.35 10.35 0 0 0-.456.938 13.702 13.702 0 0 0-4.115 0 9.479 9.479 0 0 0-.464-.938.058.058 0 0 0-.058-.027c-1.266.218-2.497.6-3.664 1.136a.052.052 0 0 0-.024.02C1.4 8.023.76 11.424 1.074 14.782a.062.062 0 0 0 .024.042 14.923 14.923 0 0 0 4.494 2.272.058.058 0 0 0 .064-.02c.346-.473.654-.972.92-1.496a.057.057 0 0 0-.032-.08 9.83 9.83 0 0 1-1.404-.669.058.058 0 0 1-.029-.046.058.058 0 0 1 .023-.05c.094-.07.189-.144.279-.218a.056.056 0 0 1 .058-.008c2.946 1.345 6.135 1.345 9.046 0a.056.056 0 0 1 .059.007c.09.074.184.149.28.22a.058.058 0 0 1 .023.049.059.059 0 0 1-.028.046 9.224 9.224 0 0 1-1.405.669.058.058 0 0 0-.033.033.056.056 0 0 0 .002.047c.27.523.58 1.022.92 1.495a.056.056 0 0 0 .062.021 14.878 14.878 0 0 0 4.502-2.272.055.055 0 0 0 .016-.018.056.056 0 0 0 .008-.023c.375-3.883-.63-7.256-2.662-10.246a.046.046 0 0 0-.023-.021Zm-9.223 8.221c-.887 0-1.618-.814-1.618-1.814s.717-1.814 1.618-1.814c.908 0 1.632.821 1.618 1.814 0 1-.717 1.814-1.618 1.814Zm5.981 0c-.887 0-1.618-.814-1.618-1.814s.717-1.814 1.618-1.814c.908 0 1.632.821 1.618 1.814 0 1-.71 1.814-1.618 1.814Z"></path></svg>
              </.link>
            </div>
          </div>
        </footer>
      </div>
    </div>
    """
  end

  def overview(assigns) do
    ~H"""
    <h1>Algora</h1>
    <p class="lead">
      Discover GitHub bounties, contract work and jobs. Hire the top 1% open source developers.
    </p>
    <div class="not-prose mb-16 mt-6 flex gap-3">
      <a
        class="inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition rounded-full bg-gray-900 py-1 px-3 text-white hover:bg-gray-700 dark:bg-emerald-400/10 dark:text-emerald-400 dark:ring-1 dark:ring-inset dark:ring-emerald-400/20 dark:hover:bg-emerald-400/10 dark:hover:text-emerald-300 dark:hover:ring-emerald-300"
        href="/"
      >
        Get started<svg
          viewBox="0 0 20 20"
          fill="none"
          aria-hidden="true"
          class="mt-0.5 h-5 w-5 -mr-1"
        ><path
            stroke="currentColor"
            stroke-linecap="round"
            stroke-linejoin="round"
            d="m11.5 6.5 3 3.5m0 0-3 3.5m3-3.5h-9"
          ></path></svg>
      </a>
    </div>
    <div class="my-16 xl:max-w-none">
      <div class="not-prose mt-4 grid grid-cols-1 gap-8 border-t border-gray-900/5 pt-10 dark:border-white/5 sm:grid-cols-2 xl:grid-cols-4">
        <div class="group relative flex rounded-2xl bg-card transition-shadow hover:shadow-md hover:shadow-gray-900/5 dark:bg-white/2.5 dark:hover:shadow-black/5">
          <div class="pointer-events-none">
            <div class="absolute inset-0 rounded-2xl transition duration-300 [mask-image:linear-gradient(white,transparent)] group-hover:opacity-50">
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-black/[0.02] stroke-black/5 dark:fill-white/1 dark:stroke-white/2.5"
              >
                <defs>
                  <pattern
                    id=":r7:"
                    width="72"
                    height="56"
                    patternUnits="userSpaceOnUse"
                    x="50%"
                    y="16"
                  >
                    <path d="M.5 56V.5H72" fill="none"></path>
                  </pattern>
                </defs>
                <rect width="100%" height="100%" stroke-width="0" fill="url(#:r7:)"></rect>
                <svg x="50%" y="16" class="overflow-visible">
                  <rect stroke-width="0" width="73" height="57" x="0" y="56"></rect>
                  <rect stroke-width="0" width="73" height="57" x="72" y="168"></rect>
                </svg>
              </svg>
            </div>
            <div
              class="absolute inset-0 rounded-2xl bg-gradient-to-r from-[#D7EDEA] to-[#F4FBDF] opacity-0 transition duration-300 group-hover:opacity-100 dark:from-[#202D2E] dark:to-[#303428]"
              style="mask-image: radial-gradient(180px at 0px 0px, white, transparent);"
            >
            </div>
            <div
              class="absolute inset-0 rounded-2xl opacity-0 mix-blend-overlay transition duration-300 group-hover:opacity-100"
              style="mask-image: radial-gradient(180px at 0px 0px, white, transparent);"
            >
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-black/50 stroke-black/70 dark:fill-white/2.5 dark:stroke-white/10"
              >
                <defs>
                  <pattern
                    id=":r8:"
                    width="72"
                    height="56"
                    patternUnits="userSpaceOnUse"
                    x="50%"
                    y="16"
                  >
                    <path d="M.5 56V.5H72" fill="none"></path>
                  </pattern>
                </defs>
                <rect width="100%" height="100%" stroke-width="0" fill="url(#:r8:)"></rect>
                <svg x="50%" y="16" class="overflow-visible">
                  <rect stroke-width="0" width="73" height="57" x="0" y="56"></rect>
                  <rect stroke-width="0" width="73" height="57" x="72" y="168"></rect>
                </svg>
              </svg>
            </div>
          </div>
          <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-gray-900/7.5 group-hover:ring-gray-900/10 dark:ring-white/10 dark:group-hover:ring-white/20">
          </div>
          <div class="relative rounded-2xl px-4 pt-16 pb-4">
            <div class="flex h-7 w-7 items-center justify-center rounded-full bg-gray-900/5 ring-1 ring-gray-900/25 backdrop-blur-[2px] transition duration-300 group-hover:bg-white/50 group-hover:ring-gray-900/25 dark:bg-white/7.5 dark:ring-white/15 dark:group-hover:bg-emerald-300/10 dark:group-hover:ring-emerald-400">
              <.icon
                name="tabler-diamond"
                class="h-5 w-5 fill-gray-700/10 stroke-gray-700 transition-colors duration-300 group-hover:stroke-gray-900 dark:fill-white/10 dark:stroke-gray-400 dark:group-hover:fill-emerald-300/10 dark:group-hover:stroke-emerald-400"
              />
            </div>
            <h3 class="mt-4 text-sm font-semibold leading-7 text-gray-900 dark:text-white">
              <a href="/docs/streaming/quickstart">
                <span class="absolute inset-0 rounded-2xl"></span>Bounties
              </a>
            </h3>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Add USD rewards on issues and pay on-merge
            </p>
          </div>
        </div>
        <div class="group relative flex rounded-2xl bg-card transition-shadow hover:shadow-md hover:shadow-gray-900/5 dark:bg-white/2.5 dark:hover:shadow-black/5">
          <div class="pointer-events-none">
            <div class="absolute inset-0 rounded-2xl transition duration-300 [mask-image:linear-gradient(white,transparent)] group-hover:opacity-50">
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-black/[0.02] stroke-black/5 dark:fill-white/1 dark:stroke-white/2.5"
              >
                <defs>
                  <pattern
                    id=":r9:"
                    width="72"
                    height="56"
                    patternUnits="userSpaceOnUse"
                    x="50%"
                    y="32"
                  >
                    <path d="M.5 56V.5H72" fill="none"></path>
                  </pattern>
                </defs>
                <rect width="100%" height="100%" stroke-width="0" fill="url(#:r9:)"></rect>
                <svg x="50%" y="32" class="overflow-visible">
                  <rect stroke-width="0" width="73" height="57" x="0" y="112"></rect>
                  <rect stroke-width="0" width="73" height="57" x="72" y="224"></rect>
                </svg>
              </svg>
            </div>
            <div
              class="absolute inset-0 rounded-2xl bg-gradient-to-r from-[#D7EDEA] to-[#F4FBDF] opacity-0 transition duration-300 group-hover:opacity-100 dark:from-[#202D2E] dark:to-[#303428]"
              style="mask-image: radial-gradient(180px at 0px 0px, white, transparent);"
            >
            </div>
            <div
              class="absolute inset-0 rounded-2xl opacity-0 mix-blend-overlay transition duration-300 group-hover:opacity-100"
              style="mask-image: radial-gradient(180px at 0px 0px, white, transparent);"
            >
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-black/50 stroke-black/70 dark:fill-white/2.5 dark:stroke-white/10"
              >
                <defs>
                  <pattern
                    id=":ra:"
                    width="72"
                    height="56"
                    patternUnits="userSpaceOnUse"
                    x="50%"
                    y="32"
                  >
                    <path d="M.5 56V.5H72" fill="none"></path>
                  </pattern>
                </defs>
                <rect width="100%" height="100%" stroke-width="0" fill="url(#:ra:)"></rect>
                <svg x="50%" y="32" class="overflow-visible">
                  <rect stroke-width="0" width="73" height="57" x="0" y="112"></rect>
                  <rect stroke-width="0" width="73" height="57" x="72" y="224"></rect>
                </svg>
              </svg>
            </div>
          </div>
          <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-gray-900/7.5 group-hover:ring-gray-900/10 dark:ring-white/10 dark:group-hover:ring-white/20">
          </div>
          <div class="relative rounded-2xl px-4 pt-16 pb-4">
            <div class="flex h-7 w-7 items-center justify-center rounded-full bg-gray-900/5 ring-1 ring-gray-900/25 backdrop-blur-[2px] transition duration-300 group-hover:bg-white/50 group-hover:ring-gray-900/25 dark:bg-white/7.5 dark:ring-white/15 dark:group-hover:bg-emerald-300/10 dark:group-hover:ring-emerald-400">
              <.icon
                name="tabler-contract"
                class="h-5 w-5 fill-gray-700/10 stroke-gray-700 transition-colors duration-300 group-hover:stroke-gray-900 dark:fill-white/10 dark:stroke-gray-400 dark:group-hover:fill-emerald-300/10 dark:group-hover:stroke-emerald-400"
              />
            </div>
            <h3 class="mt-4 text-sm font-semibold leading-7 text-gray-900 dark:text-white">
              <a href="#">
                <span class="absolute inset-0 rounded-2xl"></span>Contract work
              </a>
            </h3>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Collaborate flexibly, hourly or fixed rate
            </p>
          </div>
        </div>
        <div class="group relative flex rounded-2xl bg-card transition-shadow hover:shadow-md hover:shadow-gray-900/5 dark:bg-white/2.5 dark:hover:shadow-black/5">
          <div class="pointer-events-none">
            <div class="absolute inset-0 rounded-2xl transition duration-300 [mask-image:linear-gradient(white,transparent)] group-hover:opacity-50">
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-black/[0.02] stroke-black/5 dark:fill-white/1 dark:stroke-white/2.5"
              >
                <defs>
                  <pattern
                    id=":rb:"
                    width="72"
                    height="56"
                    patternUnits="userSpaceOnUse"
                    x="50%"
                    y="-6"
                  >
                    <path d="M.5 56V.5H72" fill="none"></path>
                  </pattern>
                </defs>
                <rect width="100%" height="100%" stroke-width="0" fill="url(#:rb:)"></rect>
                <svg x="50%" y="-6" class="overflow-visible">
                  <rect stroke-width="0" width="73" height="57" x="-72" y="112"></rect>
                  <rect stroke-width="0" width="73" height="57" x="72" y="168"></rect>
                </svg>
              </svg>
            </div>
            <div
              class="absolute inset-0 rounded-2xl bg-gradient-to-r from-[#D7EDEA] to-[#F4FBDF] opacity-0 transition duration-300 group-hover:opacity-100 dark:from-[#202D2E] dark:to-[#303428]"
              style="mask-image: radial-gradient(180px at 230.333px 51.1111px, white, transparent);"
            >
            </div>
            <div
              class="absolute inset-0 rounded-2xl opacity-0 mix-blend-overlay transition duration-300 group-hover:opacity-100"
              style="mask-image: radial-gradient(180px at 230.333px 51.1111px, white, transparent);"
            >
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-black/50 stroke-black/70 dark:fill-white/2.5 dark:stroke-white/10"
              >
                <defs>
                  <pattern
                    id=":rc:"
                    width="72"
                    height="56"
                    patternUnits="userSpaceOnUse"
                    x="50%"
                    y="-6"
                  >
                    <path d="M.5 56V.5H72" fill="none"></path>
                  </pattern>
                </defs>
                <rect width="100%" height="100%" stroke-width="0" fill="url(#:rc:)"></rect>
                <svg x="50%" y="-6" class="overflow-visible">
                  <rect stroke-width="0" width="73" height="57" x="-72" y="112"></rect>
                  <rect stroke-width="0" width="73" height="57" x="72" y="168"></rect>
                </svg>
              </svg>
            </div>
          </div>
          <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-gray-900/7.5 group-hover:ring-gray-900/10 dark:ring-white/10 dark:group-hover:ring-white/20">
          </div>
          <div class="relative rounded-2xl px-4 pt-16 pb-4">
            <div class="flex h-7 w-7 items-center justify-center rounded-full bg-gray-900/5 ring-1 ring-gray-900/25 backdrop-blur-[2px] transition duration-300 group-hover:bg-white/50 group-hover:ring-gray-900/25 dark:bg-white/7.5 dark:ring-white/15 dark:group-hover:bg-emerald-300/10 dark:group-hover:ring-emerald-400">
              <.icon
                name="tabler-user-star"
                class="h-5 w-5 fill-gray-700/10 stroke-gray-700 transition-colors duration-300 group-hover:stroke-gray-900 dark:fill-white/10 dark:stroke-gray-400 dark:group-hover:fill-emerald-300/10 dark:group-hover:stroke-emerald-400"
              />
            </div>
            <h3 class="mt-4 text-sm font-semibold leading-7 text-gray-900 dark:text-white">
              <a href="#">
                <span class="absolute inset-0 rounded-2xl"></span>Marketplace
              </a>
            </h3>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Collaborate with Algora experts
            </p>
          </div>
        </div>
        <div class="group relative flex rounded-2xl bg-card transition-shadow hover:shadow-md hover:shadow-gray-900/5 dark:bg-white/2.5 dark:hover:shadow-black/5">
          <div class="pointer-events-none">
            <div class="absolute inset-0 rounded-2xl transition duration-300 [mask-image:linear-gradient(white,transparent)] group-hover:opacity-50">
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-black/[0.02] stroke-black/5 dark:fill-white/1 dark:stroke-white/2.5"
              >
                <defs>
                  <pattern
                    id=":rd:"
                    width="72"
                    height="56"
                    patternUnits="userSpaceOnUse"
                    x="50%"
                    y="22"
                  >
                    <path d="M.5 56V.5H72" fill="none"></path>
                  </pattern>
                </defs>
                <rect width="100%" height="100%" stroke-width="0" fill="url(#:rd:)"></rect>
                <svg x="50%" y="22" class="overflow-visible">
                  <rect stroke-width="0" width="73" height="57" x="0" y="56"></rect>
                </svg>
              </svg>
            </div>
            <div
              class="absolute inset-0 rounded-2xl bg-gradient-to-r from-[#D7EDEA] to-[#F4FBDF] opacity-0 transition duration-300 group-hover:opacity-100 dark:from-[#202D2E] dark:to-[#303428]"
              style="mask-image: radial-gradient(180px at 208.333px 143.111px, white, transparent);"
            >
            </div>
            <div
              class="absolute inset-0 rounded-2xl opacity-0 mix-blend-overlay transition duration-300 group-hover:opacity-100"
              style="mask-image: radial-gradient(180px at 208.333px 143.111px, white, transparent);"
            >
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-black/50 stroke-black/70 dark:fill-white/2.5 dark:stroke-white/10"
              >
                <defs>
                  <pattern
                    id=":re:"
                    width="72"
                    height="56"
                    patternUnits="userSpaceOnUse"
                    x="50%"
                    y="22"
                  >
                    <path d="M.5 56V.5H72" fill="none"></path>
                  </pattern>
                </defs>
                <rect width="100%" height="100%" stroke-width="0" fill="url(#:re:)"></rect>
                <svg x="50%" y="22" class="overflow-visible">
                  <rect stroke-width="0" width="73" height="57" x="0" y="56"></rect>
                </svg>
              </svg>
            </div>
          </div>
          <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-gray-900/7.5 group-hover:ring-gray-900/10 dark:ring-white/10 dark:group-hover:ring-white/20">
          </div>
          <div class="relative rounded-2xl px-4 pt-16 pb-4">
            <div class="flex h-7 w-7 items-center justify-center rounded-full bg-gray-900/5 ring-1 ring-gray-900/25 backdrop-blur-[2px] transition duration-300 group-hover:bg-white/50 group-hover:ring-gray-900/25 dark:bg-white/7.5 dark:ring-white/15 dark:group-hover:bg-emerald-300/10 dark:group-hover:ring-emerald-400">
              <.icon
                name="tabler-image-in-picture"
                class="h-5 w-5 fill-gray-700/10 stroke-gray-700 transition-colors duration-300 group-hover:stroke-gray-900 dark:fill-white/10 dark:stroke-gray-400 dark:group-hover:fill-emerald-300/10 dark:group-hover:stroke-emerald-400"
              />
            </div>
            <h3 class="mt-4 text-sm font-semibold leading-7 text-gray-900 dark:text-white">
              <a href="#">
                <span class="absolute inset-0 rounded-2xl"></span>Embed
              </a>
            </h3>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Embed Algora in your website, readme, docs, etc.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
