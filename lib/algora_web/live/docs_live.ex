defmodule AlgoraWeb.DocsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  defp nav do
    [
      %{
        title: "Overview",
        links: [
          %{title: "Introduction", href: "/docs"},
          %{title: "Slash commands", href: "/docs/commands"}
        ]
      },
      %{
        title: "GitHub bounties",
        links: [
          %{title: "Create bounties in your repos", href: "/docs/bounties/in-your-own-repos"},
          %{title: "Fund issues anywhere on GitHub", href: "/docs/bounties/in-other-projects"}
        ]
      },
      %{
        title: "Algora bounties",
        links: [
          %{title: "Exclusive", href: "/docs/bounties/exclusive"},
          %{title: "Custom", href: "/docs/bounties/custom"}
        ]
      },
      %{
        title: "Tips",
        links: [
          %{title: "Send a tip", href: "/docs/tips/send"}
        ]
      },
      %{
        title: "Contracts",
        links: [
          %{title: "Offer a contract", href: "/docs/contracts/offer-contract"}
        ]
      },
      %{
        title: "Marketplace",
        links: [
          %{title: "Matches", href: "/docs/marketplace/matches"}
        ]
      },
      %{
        title: "Workspace",
        links: [
          %{title: "Bounty board", href: "/docs/workspace/bounty-board"},
          %{title: "Leaderboard", href: "/docs/workspace/leaderboard"},
          %{title: "Transactions", href: "/docs/workspace/transactions"},
          %{title: "Autopay on merge", href: "/docs/workspace/autopay"},
          %{title: "Custom bot messages", href: "/docs/workspace/custom-bot-messages"}
        ]
      },
      %{
        title: "Embed",
        links: [
          %{title: "SDK", href: "/docs/embed/sdk"},
          %{title: "Shields", href: "/docs/embed/shields"},
          %{title: "Socials", href: "/docs/embed/socials"}
        ]
      },
      %{
        title: "Payments",
        links: [
          %{title: "Payments", href: "/docs/payments"},
          %{title: "Reporting", href: "/docs/payments/reporting"}
        ]
      }
    ]
  end

  @impl true
  def mount(%{"path" => []}, _session, socket) do
    docs = Algora.Content.list_content_rec("docs")
    {:ok, assign(socket, docs: docs, page_title: "Docs", path: [])}
  end

  @impl true
  def mount(%{"path" => path}, _session, socket) do
    slug = List.last(path)
    dir = Path.join("docs", Enum.drop(path, -1))

    case Algora.Content.load_content(dir, slug) do
      {:ok, content} ->
        {:ok, assign(socket, content: content, page_title: content.title, path: path)}

      {:error, _reason} ->
        {:ok, push_navigate(socket, to: ~p"/docs")}
    end
  end

  defp active?(current_path, href), do: Path.join(["/docs" | current_path]) == href

  defp render_navigation_section(assigns) do
    ~H"""
    <li :for={section <- nav()} class="relative mt-6">
      <h2 class="text-xs font-semibold text-white light:text-gray-900">
        {section.title}
      </h2>
      <div class="relative mt-3 pl-2">
        <div class="absolute inset-y-0 left-2 w-px bg-white/5 light:bg-gray-900/10"></div>
        <ul role="list" class="border-l border-transparent">
          <%= for link <- section.links do %>
            <li class="relative">
              <.link
                href={link.href}
                class={
                  classes([
                    "flex justify-between gap-2 py-1 pr-3 text-sm transition pl-4 text-gray-400 hover:text-white light:text-gray-600 light:hover:text-gray-900",
                    if(active?(assigns.path, link.href), do: "border-l-2 border-emerald-400")
                  ])
                }
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
    <div class="lg:ml-72 xl:ml-80">
      <header class="bg-black fixed inset-y-0 left-0 z-40 contents w-72 overflow-y-auto scrollbar-thin border-r border-white/10 light:border-gray-900/10 px-6 pt-4 pb-8 lg:block xl:w-80">
        <div
          class="hidden fixed inset-0 z-50 lg:hidden"
          id="mobile-menu"
          role="dialog"
          aria-modal="true"
        >
          <div class="fixed inset-0 top-14 bg-black/40 light:bg-gray-400/20 backdrop-blur-sm opacity-100">
          </div>
          <div id="headlessui-dialog-panel-:r1g:" data-headlessui-state="open">
            <div
              class="fixed inset-x-0 top-0 z-50 flex h-14 items-center justify-between gap-5 px-4 transition sm:px-6 lg:z-30 lg:px-8 bg-black light:bg-white opacity-100"
              data-projection-id="31"
              style="--bg-opacity-light: 0.5; --bg-opacity-dark: 0.2;"
            >
              <div class="absolute inset-x-0 top-full h-px transition bg-white/7.5 light:bg-gray-900/7.5">
              </div>
              <div class="hidden md:block"></div>
              <div class="flex w-full items-center justify-between gap-5 lg:hidden">
                <a aria-label="Home" href="/docs" tabindex="0">
                  <svg viewBox="0 0 100.14 39.42" aria-hidden="true" class="h-6">
                    <path
                      class="fill-white light:fill-gray-900"
                      d="M19.25 9v19.24H16v-2.37a9.63 9.63 0 1 1 0-14.51V9ZM16 18.63A6.32 6.32 0 1 0 9.64 25 6.32 6.32 0 0 0 16 18.63Z"
                    >
                    </path>
                    <path class="fill-white light:fill-gray-900" d="M22.29 0h3.29v28.24h-3.29Z">
                    </path>
                    <path
                      class="fill-white light:fill-gray-900"
                      d="M47.6 34.27v.07a5.41 5.41 0 0 1-.69 2.52 4.78 4.78 0 0 1-1.39 1.54 5.61 5.61 0 0 1-3.25 1H34a5.21 5.21 0 0 1-3.88-1.5 6.25 6.25 0 0 1-1.53-4.2l3.29.11a2.58 2.58 0 0 0 .62 1.83 2 2 0 0 0 1.5.47h8.29c1.68 0 2-1.1 2-1.75a2 2 0 0 0-2-1.76h-8.2a5.35 5.35 0 0 1-5.52-5.51 6.07 6.07 0 0 1 1.24-3.62 9.5 9.5 0 0 1-1.31-4.86A9.62 9.62 0 0 1 38.11 9a9.72 9.72 0 0 1 5.37 1.61A5.78 5.78 0 0 1 47.53 9v3.28a2.54 2.54 0 0 0-1.72.63 9.67 9.67 0 0 1 1.86 5.7 9.79 9.79 0 0 1-5.44 8.7 10 10 0 0 1-4.16.91 9.75 9.75 0 0 1-6.07-2.1 3 3 0 0 0-.18.95 2.08 2.08 0 0 0 2.23 2.27h8.18a5.61 5.61 0 0 1 3.25 1.05 5.45 5.45 0 0 1 2.12 3.88ZM31.78 18.63a6.46 6.46 0 0 0 .84 3.15 5.88 5.88 0 0 0 1.43 1.71A6.34 6.34 0 0 0 38.11 25a6.26 6.26 0 0 0 6.32-6.32 6.27 6.27 0 0 0-2.16-4.71 6.2 6.2 0 0 0-4.16-1.61 6.35 6.35 0 0 0-6.33 6.27Z"
                    >
                    </path>
                    <path
                      class="fill-white light:fill-gray-900"
                      d="M68.54 18.63A9.63 9.63 0 1 1 58.93 9a9.62 9.62 0 0 1 9.61 9.63Zm-9.61-6.32a6.32 6.32 0 1 0 6.32 6.32 6.35 6.35 0 0 0-6.32-6.32Z"
                    >
                    </path>
                    <path
                      class="fill-white light:fill-gray-900"
                      d="M80.35 14.1h-3.28a1.9 1.9 0 0 0-.4-1.31 2 2 0 0 0-1.28-.48 1.83 1.83 0 0 0-2 1.57v14.36h-3.27V9h3.29v.4a5.24 5.24 0 0 1 1.9-.4 5.47 5.47 0 0 1 3.62 1.35 5 5 0 0 1 1.42 3.75Z"
                    >
                    </path>
                    <path
                      class="fill-white light:fill-gray-900"
                      d="M100.14 9v19.24h-3.29v-2.37a9.63 9.63 0 1 1 0-14.51V9Zm-3.29 9.64A6.32 6.32 0 1 0 90.53 25a6.32 6.32 0 0 0 6.32-6.37Z"
                    >
                    </path>
                  </svg>
                </a>
                <button
                  type="button"
                  class="flex items-center justify-center rounded-md transition hover:bg-white/5 light:hover:bg-gray-900/5"
                  aria-label="Toggle navigation"
                  phx-click={JS.toggle(to: "#mobile-menu")}
                >
                  <svg
                    viewBox="0 0 10 9"
                    fill="none"
                    stroke-linecap="round"
                    aria-hidden="true"
                    class="h-5 w-5 stroke-white light:stroke-gray-900"
                  >
                    <path d="m1.5 1 7 7M8.5 1l-7 7"></path>
                  </svg>
                </button>
              </div>
              <div class="flex items-center gap-5">
                <nav class="hidden md:block">
                  <ul role="list" class="flex items-center gap-8">
                    <li>
                      <a
                        class="text-sm leading-5 text-gray-400 hover:text-white light:text-gray-600 light:hover:text-gray-900"
                        href="/docs/contact"
                      >
                        Contact
                      </a>
                    </li>
                  </ul>
                </nav>
                <div class="hidden md:block md:h-5 md:w-px md:bg-white/15 light:md:bg-gray-900/10">
                </div>
                <div class="hidden whitespace-nowrap md:contents">
                  <a
                    class="px-3 py-1 inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition rounded-full bg-emerald-400/10 text-emerald-400 ring-1 ring-inset ring-emerald-400/20 hover:bg-emerald-400/10 hover:text-emerald-300 hover:ring-emerald-300 light:bg-gray-900 light:text-white light:hover:bg-gray-700"
                    href="/"
                  >
                    Get started
                  </a>
                </div>
              </div>
            </div>
            <div
              class="fixed left-0 top-14 bottom-0 w-full overflow-y-auto bg-black light:bg-white px-4 pt-6 pb-4 shadow-lg shadow-gray-800 light:shadow-gray-900/10 ring-1 ring-gray-800 light:ring-gray-900/7.5 sm:px-6 sm:pb-10 md:max-w-sm translate-x-0"
              data-projection-id="32"
            >
              <nav>
                <ul role="list">
                  <li :for={section <- nav()} class="relative mt-6">
                    <h2
                      class="text-xs font-semibold text-white light:text-gray-900"
                      data-projection-id="36"
                    >
                      {section.title}
                    </h2>
                    <div class="relative mt-3 pl-2">
                      <ul role="list" class="border-l border-transparent">
                        <li :for={link <- section.links} class="relative" data-projection-id="40">
                          <a
                            class="flex justify-between gap-2 py-1 pr-3 text-sm transition pl-4 text-gray-400 hover:text-white light:text-gray-600 light:hover:text-gray-900"
                            href={link.href}
                          >
                            <span class="truncate">{link.title}</span>
                          </a>
                        </li>
                      </ul>
                    </div>
                  </li>
                </ul>
              </nav>
            </div>
          </div>
        </div>
        <div class="hidden lg:flex">
          <.wordmark class="h-8 w-auto text-foreground" />
        </div>
        <div
          class="fixed inset-x-0 top-0 z-50 flex h-14 items-center justify-between gap-5 px-4 transition sm:px-6 lg:z-30 lg:px-8 backdrop-blur-sm lg:left-72 xl:left-80 bg-gray-900/[var(--bg-opacity-dark)] light:bg-white/[var(--bg-opacity-light)]"
          style="--bg-opacity-light: 0.5; --bg-opacity-dark: 0.2;"
        >
          <div class="absolute inset-x-0 top-full h-px transition bg-white/7.5 light:bg-gray-900/7.5">
          </div>
          <div class="hidden md:block"></div>
          <div class="flex w-full items-center justify-between gap-5 lg:hidden">
            <.wordmark class="h-6 w-auto text-foreground" />
            <button
              type="button"
              class="flex items-center justify-center rounded-md transition hover:bg-white/5 light:hover:bg-gray-900/5"
              aria-label="Toggle navigation"
              phx-click={JS.toggle(to: "#mobile-menu")}
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
                class="h-5 w-5 stroke-white light:stroke-gray-900"
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
                    class="text-sm leading-5 text-gray-400 hover:text-white light:text-gray-600 light:hover:text-gray-900"
                    href="/docs/contact"
                  >
                    Contact
                  </a>
                </li>
              </ul>
            </nav>
            <div class="hidden md:block md:h-5 md:w-px md:bg-white/15 light:md:bg-gray-900/10"></div>
            <div class="hidden whitespace-nowrap md:contents">
              <a
                class="px-3 py-1 inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition rounded-full bg-emerald-400/10 text-emerald-400 ring-1 ring-inset ring-emerald-400/20 hover:bg-emerald-400/10 hover:text-emerald-300 hover:ring-emerald-300 light:bg-gray-900 light:text-white light:hover:bg-gray-700"
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
                class="block py-1 text-sm text-gray-400 hover:text-white light:text-gray-600 light:hover:text-gray-900"
                href="https://docs.algora.io"
              >
                Documentation
              </a>
            </li>
            <li class="md:hidden">
              <a
                class="block py-1 text-sm text-gray-400 hover:text-white light:text-gray-600 light:hover:text-gray-900"
                href="mailto:info@algora.io"
              >
                Contact
              </a>
            </li>
            {render_navigation_section(assigns)}
            <li class="sticky bottom-0 z-10 mt-6 md:hidden">
              <a
                class="px-3 py-1 inline-flex gap-0.5 justify-center overflow-hidden text-sm font-medium transition rounded-full bg-emerald-400/10 text-emerald-400 ring-1 ring-inset ring-emerald-400/20 hover:bg-emerald-400/10 hover:text-emerald-300 hover:ring-emerald-300 light:bg-gray-900 light:text-white light:hover:bg-gray-700"
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
          <article class="prose prose-invert light:prose max-w-5xl min-h-[calc(100svh-17rem)]">
            <div class="bg-black absolute -z-10 inset-0 mx-0 max-w-none overflow-hidden">
              <div class="absolute [mask-image:linear-gradient(white,transparent)] h-[25rem] left-1/2 ml-[-38rem] top-0 w-[81.25rem]">
                <div class="absolute inset-0 bg-gradient-to-r light:from-[#36b49f] light:to-[#DBFF75] light:opacity-40 [mask-image:radial-gradient(farthest-side_at_top,white,transparent)] from-[#36b49f]/30 to-[#DBFF75]/30 opacity-100">
                  <svg
                    aria-hidden="true"
                    class="absolute inset-x-0 inset-y-[-50%] h-[200%] w-full skew-y-[-18deg] light:fill-black/40 light:stroke-black/50 mix-blend-overlay fill-white/2.5 stroke-white/5"
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
              </div>
            </div>
            <%= if assigns[:content] do %>
              {raw(@content.content)}
            <% else %>
              <.overview />
            <% end %>
          </article>
        </main>
        <footer class="max-w-2xl space-y-10 pb-8 lg:max-w-none">
          <div class="flex flex-col items-center justify-between gap-5 border-t border-white/5 light:border-gray-900/5 pt-8 sm:flex-row">
            <p class="text-xs text-gray-400 light:text-gray-600">
              © {DateTime.utc_now().year} Algora, Public Benefit Corporation
            </p>
            <div class="flex gap-4">
              <.link
                class="group"
                href={AlgoraWeb.Constants.get(:twitter_url)}
                rel="noopener"
                target="_blank"
              >
                <span class="sr-only">Follow us on Twitter</span>
                <svg
                  viewBox="0 0 20 20"
                  aria-hidden="true"
                  class="h-5 w-5 fill-gray-400 group-hover:fill-gray-500 light:fill-gray-700 light:group-hover:fill-gray-900"
                >
                  <path d="M16.712 6.652c.01.146.01.29.01.436 0 4.449-3.267 9.579-9.242 9.579v-.003a8.963 8.963 0 0 1-4.98-1.509 6.379 6.379 0 0 0 4.807-1.396c-1.39-.027-2.608-.966-3.035-2.337.487.097.99.077 1.467-.059-1.514-.316-2.606-1.696-2.606-3.3v-.041c.45.26.956.404 1.475.42C3.18 7.454 2.74 5.486 3.602 3.947c1.65 2.104 4.083 3.382 6.695 3.517a3.446 3.446 0 0 1 .94-3.217 3.172 3.172 0 0 1 4.596.148 6.38 6.38 0 0 0 2.063-.817 3.357 3.357 0 0 1-1.428 1.861 6.283 6.283 0 0 0 1.865-.53 6.735 6.735 0 0 1-1.62 1.744Z">
                  </path>
                </svg>
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
                  class="h-5 w-5 fill-gray-400 group-hover:fill-gray-500 light:fill-gray-700 light:group-hover:fill-gray-900"
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
        class="px-3 py-1 inline-flex gap-0.5 items-center justify-center overflow-hidden text-sm font-medium transition rounded-full bg-emerald-400/10 text-emerald-400 ring-1 ring-inset ring-emerald-400/20 hover:bg-emerald-400/10 hover:text-emerald-300 hover:ring-emerald-300 light:bg-gray-900 light:text-white light:hover:bg-gray-700"
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
      <div class="not-prose mt-4 grid grid-cols-1 gap-8 border-t border-white/5 light:border-gray-900/5 pt-10 sm:grid-cols-2 xl:grid-cols-4">
        <div class="group relative flex rounded-2xl bg-white/[2.5%] light:bg-background transition-shadow hover:shadow-md hover:shadow-black/5 light:hover:shadow-gray-900/5">
          <div class="pointer-events-none">
            <div class="absolute inset-0 rounded-2xl transition duration-300 [mask-image:linear-gradient(white,transparent)] group-hover:opacity-50">
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-white/1 stroke-white/2.5 light:fill-black/[0.02] light:stroke-black/5"
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
              class="absolute inset-0 rounded-2xl bg-gradient-to-r from-[#202D2E] to-[#303428] opacity-0 transition duration-300 group-hover:opacity-100 light:from-[#D7EDEA] light:to-[#F4FBDF]"
              style="mask-image: radial-gradient(180px at 0px 0px, white, transparent);"
            >
            </div>
            <div
              class="absolute inset-0 rounded-2xl opacity-0 mix-blend-overlay transition duration-300 group-hover:opacity-100"
              style="mask-image: radial-gradient(180px at 0px 0px, white, transparent);"
            >
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-white/2.5 stroke-white/10 light:fill-black/50 light:stroke-black/70"
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
          <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-white/10 group-hover:ring-white/20 light:ring-gray-900/7.5 light:group-hover:ring-gray-900/10">
          </div>
          <div class="relative rounded-2xl px-4 pt-16 pb-4">
            <div class="flex h-7 w-7 items-center justify-center rounded-full bg-white/7.5 ring-1 ring-white/15 backdrop-blur-[2px] transition duration-300 group-hover:bg-emerald-300/10 group-hover:ring-emerald-400 light:bg-gray-900/5 light:ring-gray-900/25 light:group-hover:bg-white/50 light:group-hover:ring-gray-900/25">
              <.icon
                name="tabler-diamond"
                class="h-5 w-5 fill-white/10 text-gray-400 transition-colors duration-300 group-hover:fill-emerald-300/10 group-hover:text-emerald-400 light:fill-gray-700/10 light:text-gray-700 light:group-hover:text-gray-900"
              />
            </div>
            <h3 class="mt-4 text-sm font-semibold leading-7 text-white light:text-gray-900">
              <.link navigate="/docs/bounties/in-your-own-repos">
                <span class="absolute inset-0 rounded-2xl"></span>Bounties
              </.link>
            </h3>
            <p class="mt-1 text-sm text-gray-400 light:text-gray-600">
              Add USD rewards on issues and pay on-merge
            </p>
          </div>
        </div>
        <div class="group relative flex rounded-2xl bg-white/[2.5%] light:bg-background transition-shadow hover:shadow-md hover:shadow-black/5 light:hover:shadow-gray-900/5">
          <div class="pointer-events-none">
            <div class="absolute inset-0 rounded-2xl transition duration-300 [mask-image:linear-gradient(white,transparent)] group-hover:opacity-50">
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-white/1 stroke-white/2.5 light:fill-black/[0.02] light:stroke-black/5"
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
              class="absolute inset-0 rounded-2xl bg-gradient-to-r from-[#202D2E] to-[#303428] opacity-0 transition duration-300 group-hover:opacity-100 light:from-[#D7EDEA] light:to-[#F4FBDF]"
              style="mask-image: radial-gradient(180px at 0px 0px, white, transparent);"
            >
            </div>
            <div
              class="absolute inset-0 rounded-2xl opacity-0 mix-blend-overlay transition duration-300 group-hover:opacity-100"
              style="mask-image: radial-gradient(180px at 0px 0px, white, transparent);"
            >
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-white/2.5 stroke-white/10 light:fill-black/50 light:stroke-black/70"
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
          <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-white/10 group-hover:ring-white/20 light:ring-gray-900/7.5 light:group-hover:ring-gray-900/10">
          </div>
          <div class="relative rounded-2xl px-4 pt-16 pb-4">
            <div class="flex h-7 w-7 items-center justify-center rounded-full bg-white/7.5 ring-1 ring-white/15 backdrop-blur-[2px] transition duration-300 group-hover:bg-emerald-300/10 group-hover:ring-emerald-400 light:bg-gray-900/5 light:ring-gray-900/25 light:group-hover:bg-white/50 light:group-hover:ring-gray-900/25">
              <.icon
                name="tabler-contract"
                class="h-5 w-5 fill-white/10 text-gray-400 transition-colors duration-300 group-hover:fill-emerald-300/10 group-hover:text-emerald-400 light:fill-gray-700/10 light:text-gray-700 light:group-hover:text-gray-900"
              />
            </div>
            <h3 class="mt-4 text-sm font-semibold leading-7 text-white light:text-gray-900">
              <.link navigate="/docs/contracts/offer-contract">
                <span class="absolute inset-0 rounded-2xl"></span>Contract work
              </.link>
            </h3>
            <p class="mt-1 text-sm text-gray-400 light:text-gray-600">
              Collaborate flexibly, hourly or fixed rate
            </p>
          </div>
        </div>
        <div class="group relative flex rounded-2xl bg-white/[2.5%] light:bg-background transition-shadow hover:shadow-md hover:shadow-black/5 light:hover:shadow-gray-900/5">
          <div class="pointer-events-none">
            <div class="absolute inset-0 rounded-2xl transition duration-300 [mask-image:linear-gradient(white,transparent)] group-hover:opacity-50">
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-white/1 stroke-white/2.5 light:fill-black/[0.02] light:stroke-black/5"
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
              class="absolute inset-0 rounded-2xl bg-gradient-to-r from-[#202D2E] to-[#303428] opacity-0 transition duration-300 group-hover:opacity-100 light:from-[#D7EDEA] light:to-[#F4FBDF]"
              style="mask-image: radial-gradient(180px at 230.333px 51.1111px, white, transparent);"
            >
            </div>
            <div
              class="absolute inset-0 rounded-2xl opacity-0 mix-blend-overlay transition duration-300 group-hover:opacity-100"
              style="mask-image: radial-gradient(180px at 230.333px 51.1111px, white, transparent);"
            >
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-white/2.5 stroke-white/10 light:fill-black/50 light:stroke-black/70"
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
          <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-white/10 group-hover:ring-white/20 light:ring-gray-900/7.5 light:group-hover:ring-gray-900/10">
          </div>
          <div class="relative rounded-2xl px-4 pt-16 pb-4">
            <div class="flex h-7 w-7 items-center justify-center rounded-full bg-white/7.5 ring-1 ring-white/15 backdrop-blur-[2px] transition duration-300 group-hover:bg-emerald-300/10 group-hover:ring-emerald-400 light:bg-gray-900/5 light:ring-gray-900/25 light:group-hover:bg-white/50 light:group-hover:ring-gray-900/25">
              <.icon
                name="tabler-user-star"
                class="h-5 w-5 fill-white/10 text-gray-400 transition-colors duration-300 group-hover:fill-emerald-300/10 group-hover:text-emerald-400 light:fill-gray-700/10 light:text-gray-700 light:group-hover:text-gray-900"
              />
            </div>
            <h3 class="mt-4 text-sm font-semibold leading-7 text-white light:text-gray-900">
              <.link navigate="/docs/marketplace/matches">
                <span class="absolute inset-0 rounded-2xl"></span>Marketplace
              </.link>
            </h3>
            <p class="mt-1 text-sm text-gray-400 light:text-gray-600">
              Collaborate with Algora experts
            </p>
          </div>
        </div>
        <div class="group relative flex rounded-2xl bg-white/[2.5%] light:bg-background transition-shadow hover:shadow-md hover:shadow-black/5 light:hover:shadow-gray-900/5">
          <div class="pointer-events-none">
            <div class="absolute inset-0 rounded-2xl transition duration-300 [mask-image:linear-gradient(white,transparent)] group-hover:opacity-50">
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-white/1 stroke-white/2.5 light:fill-black/[0.02] light:stroke-black/5"
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
              class="absolute inset-0 rounded-2xl bg-gradient-to-r from-[#202D2E] to-[#303428] opacity-0 transition duration-300 group-hover:opacity-100 light:from-[#D7EDEA] light:to-[#F4FBDF]"
              style="mask-image: radial-gradient(180px at 208.333px 143.111px, white, transparent);"
            >
            </div>
            <div
              class="absolute inset-0 rounded-2xl opacity-0 mix-blend-overlay transition duration-300 group-hover:opacity-100"
              style="mask-image: radial-gradient(180px at 208.333px 143.111px, white, transparent);"
            >
              <svg
                aria-hidden="true"
                class="absolute inset-x-0 inset-y-[-30%] h-[160%] w-full skew-y-[-18deg] fill-white/2.5 stroke-white/10 light:fill-black/50 light:stroke-black/70"
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
          <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-white/10 group-hover:ring-white/20 light:ring-gray-900/7.5 light:group-hover:ring-gray-900/10">
          </div>
          <div class="relative rounded-2xl px-4 pt-16 pb-4">
            <div class="flex h-7 w-7 items-center justify-center rounded-full bg-white/7.5 ring-1 ring-white/15 backdrop-blur-[2px] transition duration-300 group-hover:bg-emerald-300/10 group-hover:ring-emerald-400 light:bg-gray-900/5 light:ring-gray-900/25 light:group-hover:bg-white/50 light:group-hover:ring-gray-900/25">
              <.icon
                name="tabler-image-in-picture"
                class="h-5 w-5 fill-white/10 text-gray-400 transition-colors duration-300 group-hover:fill-emerald-300/10 group-hover:text-emerald-400 light:fill-gray-700/10 light:text-gray-700 light:group-hover:text-gray-900"
              />
            </div>
            <h3 class="mt-4 text-sm font-semibold leading-7 text-white light:text-gray-900">
              <.link navigate="/docs/embed/sdk">
                <span class="absolute inset-0 rounded-2xl"></span>Embed
              </.link>
            </h3>
            <p class="mt-1 text-sm text-gray-400 light:text-gray-600">
              Embed Algora in your website, readme, docs, etc.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
