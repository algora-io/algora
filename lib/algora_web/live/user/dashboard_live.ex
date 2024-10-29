defmodule AlgoraWeb.User.DashboardLive do
  use AlgoraWeb, :live_view
  alias Algora.Bounties
  alias Algora.Money

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:tech_stack, ["Elixir", "TypeScript"])
      |> assign(:bounties, Bounties.list_bounties(status: :open, limit: 10))
      |> assign(:steps, [
        %{status: :completed, name: "Create Stripe account"},
        %{status: :completed, name: "Earn first bounty"},
        %{status: :upcoming, name: "Earn through referral"},
        %{status: :upcoming, name: "Earn $10K"},
        %{status: :upcoming, name: "Earn $50K"}
      ])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <main class="lg:pr-96">
      <div class="p-4 pt-6 sm:p-6 md:p-8">
        <div class="grid grid-cols-1 sm:grid-cols-1 lg:grid-cols-3 -ml-4 lg:-ml-8 md:pl-4">
          <div class="border-white/5 px-4 sm:px-6 lg:px-8">
            <p class="text-sm/6 font-medium text-gray-400">Earnings</p>
            <p class="mt-2 flex items-baseline gap-x-2">
              <span class="text-4xl font-semibold tracking-tight text-white">$22,100</span>
            </p>
          </div>
          <div class="border-white/5 px-4 sm:border-l sm:px-6 lg:px-8">
            <p class="text-sm/6 font-medium text-gray-400">Projects</p>
            <p class="mt-2 flex items-baseline gap-x-2">
              <span class="text-4xl font-semibold tracking-tight text-white">18</span>
            </p>
          </div>
          <div class="border-white/5 px-4 sm:px-6 lg:border-l lg:px-8">
            <p class="text-sm/6 font-medium text-gray-400">Bounties</p>
            <p class="mt-2 flex items-baseline gap-x-2">
              <span class="text-4xl font-semibold tracking-tight text-white">56</span>
            </p>
          </div>
        </div>
        <div class="pt-12">
          <header class="flex items-center justify-between md:pl-4">
            <h2 class="font-display text-2xl/7 font-semibold text-white">Bounties for you</h2>
            <a href="#" class="text-sm/6 font-semibold text-indigo-400">View all</a>
          </header>
          <div
            data-state="active"
            data-orientation="horizontal"
            role="tabpanel"
            aria-labelledby="radix-:r0:-trigger-bounties"
            id="radix-:r0:-content-bounties"
            tabindex="0"
            class="mt-2 ring-offset-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800"
            style="animation-duration: 0s;"
          >
            <div class="w-full" style="opacity: 1;">
              <div class="grid gap-x-6 gap-y-2 py-2 md:pl-4">
                <div class="space-y-1">
                  <div class="text-xs font-semibold uppercase tracking-wide text-gray-400">
                    Tech stack
                  </div>
                  <div
                    class="flex-col text-gray-950 dark:text-gray-50 flex w-full rounded-lg border border-gray-300 bg-gray-50 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 peer-[.error]:border-red-500 peer-[.error]:bg-red-50 peer-[.error]:text-red-900 peer-[.error]:placeholder-red-700 peer-[.error]:focus:border-red-500 peer-[.error]:focus:ring-red-500 dark:border-white/10 dark:bg-gray-950/50 dark:placeholder-gray-500 dark:focus:border-indigo-500 dark:focus:ring-indigo-500 peer-[.error]:dark:border-red-500 peer-[.error]:dark:bg-red-700/10 peer-[.error]:dark:text-red-500 peer-[.error]:dark:placeholder-red-500 peer-focus peer relative overflow-visible"
                    cmdk-root=""
                  >
                    <label
                      cmdk-label=""
                      for=":rb:"
                      id=":ra:"
                      style="position: absolute; width: 1px; height: 1px; padding: 0px; margin: -1px; overflow: hidden; clip: rect(0px, 0px, 0px, 0px); white-space: nowrap; border-width: 0px;"
                    >
                    </label>
                    <div class="group rounded-md border border-gray-200 px-3 py-2 text-sm ring-offset-white focus-within:ring-2 focus-within:ring-gray-400 focus-within:ring-offset-2 dark:border-gray-800 dark:ring-offset-gray-950 dark:focus-within:ring-gray-800">
                      <div class="flex flex-wrap gap-2">
                        <div class="relative h-5 flex-shrink-0">
                          <div class="pointer-events-none absolute flex min-w-max flex-wrap gap-1">
                            <div class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-gray-950 focus:ring-offset-2 dark:border-gray-300 dark:focus:ring-gray-300 border-transparent bg-gray-100 text-gray-900 hover:bg-gray-100/80 dark:bg-gray-800 dark:text-gray-50 dark:hover:bg-gray-800/80 flex-shrink-0 opacity-20">
                              typescript<button class="ml-1 rounded-full outline-none ring-offset-white focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 dark:ring-offset-gray-950 dark:focus:ring-gray-800"></button>
                            </div>
                            <div class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-gray-950 focus:ring-offset-2 dark:border-gray-300 dark:focus:ring-gray-300 border-transparent bg-gray-100 text-gray-900 hover:bg-gray-100/80 dark:bg-gray-800 dark:text-gray-50 dark:hover:bg-gray-800/80 flex-shrink-0 opacity-20">
                              nextjs<button class="ml-1 rounded-full outline-none ring-offset-white focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 dark:ring-offset-gray-950 dark:focus:ring-gray-800"></button>
                            </div>
                          </div>
                        </div>
                        <input
                          class="bg-transparent outline-none placeholder:text-gray-500 dark:placeholder:text-gray-400 absolute inset-0"
                          cmdk-input=""
                          autocomplete="off"
                          autocorrect="off"
                          spellcheck="false"
                          aria-autocomplete="list"
                          role="combobox"
                          aria-expanded="true"
                          aria-controls=":r9:"
                          aria-labelledby=":ra:"
                          id=":rb:"
                          type="text"
                          value=""
                        />
                      </div>
                    </div>
                    <div class="relative"></div>
                  </div>
                </div>
              </div>
              <div class="scrollbar-thin w-full overflow-auto">
                <table class="w-full caption-bottom text-sm">
                  <thead class="[&amp;_tr]:border-b hidden">
                    <tr class="border-b transition-colors data-[state=selected]:bg-gray-100 dark:hover:bg-gray-800/50 dark:data-[state=selected]:bg-gray-800 hover:bg-transparent">
                      <th class="h-12 px-4 text-left align-middle font-medium text-gray-500 dark:text-gray-400 [&amp;:has([role=checkbox])]:pr-0">
                      </th>
                      <th class="h-12 px-4 text-left align-middle font-medium text-gray-500 dark:text-gray-400 [&amp;:has([role=checkbox])]:pr-0 pl-[1rem] md:pl-[5.5rem]">
                      </th>
                    </tr>
                  </thead>
                  <tbody class="[&amp;_tr:last-child]:border-0">
                    <%= for bounty <- @bounties do %>
                      <tr
                        class="border-b transition-colors data-[state=selected]:bg-gray-100 dark:hover:bg-gray-800/50 dark:data-[state=selected]:bg-gray-800 hover:bg-white/[3%]"
                        style="opacity: 1;"
                      >
                        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0 w-full py-6">
                          <div class="relative flex w-full max-w-[calc(100vw-44px)] items-center gap-4">
                            <a href={~p"/org/#{bounty.owner.handle}"}>
                              <span class="relative shrink-0 overflow-hidden flex h-14 w-14 items-center justify-center rounded-xl brightness-90 transition-all group-hover:brightness-100">
                                <img
                                  class="aspect-square h-full w-full"
                                  alt={bounty.owner.name}
                                  src={bounty.owner.avatar_url}
                                />
                              </span>
                            </a>
                            <div class="w-full truncate">
                              <div class="flex items-center gap-1 whitespace-nowrap pt-px font-mono text-sm leading-none text-white/70 transition-colors md:text-base">
                                <a
                                  class="font-bold hover:text-white/80 hover:underline"
                                  href={~p"/org/#{bounty.owner.handle}"}
                                >
                                  <%= bounty.owner.name %>
                                </a>
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
                                  class="h-3 w-3 text-white/50 transition-colors"
                                  aria-hidden="true"
                                >
                                  <path d="M9 6l6 6l-6 6"></path>
                                </svg>
                                <a
                                  class="group font-medium hover:text-white/80 hover:underline"
                                  rel="noopener"
                                  href="https://github.com/SigNoz/signoz/issues/6028"
                                >
                                  <span class="hidden md:inline"><%= bounty.task.owner %>/</span><%= bounty.task.repo %><span class="hidden text-white/40 group-hover:text-white/60 md:inline">#<%= bounty.task.number %></span>
                                </a>
                              </div>
                              <a
                                rel="noopener"
                                class="group mt-1.5 flex max-w-[16rem] items-center gap-2 truncate whitespace-nowrap text-sm text-white/90 transition-colors hover:text-white md:-mt-0.5 md:max-w-2xl md:truncate md:text-base"
                                href="https://github.com/SigNoz/signoz/issues/6028"
                              >
                                <div>
                                  <div class="font-display text-base font-semibold text-emerald-300/90 transition-colors group-hover:text-emerald-300 md:text-xl">
                                    <%= Money.format!(bounty.amount, bounty.currency) %>
                                  </div>
                                </div>
                                <div class="truncate group-hover:underline">
                                  <%= bounty.task.title %>
                                </div>
                              </a>
                              <ul class="mt-2 flex flex-wrap items-center gap-1.5 md:mt-0.5">
                                <%= for tag <- bounty.tech_stack do %>
                                  <li class="flex text-sm leading-none tracking-wide transition-colors text-indigo-300/90 group-hover:text-indigo-300">
                                    #<%= tag %>
                                  </li>
                                <% end %>
                              </ul>
                            </div>
                          </div>
                        </td>
                        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
                          <div class="flex flex-row-reverse justify-center">
                            <%= if false do %>
                              <.link rel="noopener" href={bounty.url}>
                                <span class="relative shrink-0 overflow-hidden -ml-2 flex h-10 w-10 items-center justify-center rounded-full ring-4 ring-gray-800">
                                  <span class="flex h-full w-full items-center justify-center dark:bg-gray-800 rounded-full bg-gray-800">
                                    +3
                                  </span>
                                </span>
                              </.link>
                            <% end %>
                            <%= for attempter <- [] do %>
                              <.link rel="noopener" href={attempter.url}>
                                <span class="relative shrink-0 overflow-hidden -ml-2 flex h-10 w-10 items-center justify-center rounded-full bg-gray-800 ring-4 ring-gray-800">
                                  <img
                                    class="aspect-square h-full w-full"
                                    alt={attempter.name}
                                    src={attempter.avatar_url}
                                  />
                                </span>
                              </.link>
                            <% end %>
                          </div>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
          <div
            data-state="inactive"
            data-orientation="horizontal"
            role="tabpanel"
            aria-labelledby="radix-:r0:-trigger-orgs"
            hidden=""
            id="radix-:r0:-content-orgs"
            tabindex="0"
            class="mt-2 ring-offset-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800"
          >
          </div>
          <div
            data-state="inactive"
            data-orientation="horizontal"
            role="tabpanel"
            aria-labelledby="radix-:r0:-trigger-rewarded"
            hidden=""
            id="radix-:r0:-content-rewarded"
            tabindex="0"
            class="mt-2 ring-offset-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800"
          >
          </div>
          <div
            data-state="inactive"
            data-orientation="horizontal"
            role="tabpanel"
            aria-labelledby="radix-:r0:-trigger-community"
            hidden=""
            id="radix-:r0:-content-community"
            tabindex="0"
            class="mt-2 ring-offset-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800"
          >
          </div>
        </div>
      </div>
    </main>
    <!-- Activity feed -->
    <aside class="bg-black/10 lg:fixed lg:bottom-0 lg:right-0 lg:top-16 lg:w-96 lg:overflow-y-auto lg:border-l lg:border-white/5">
      <header class="flex items-center justify-between px-4 pt-4 sm:px-6 sm:pt-6 lg:px-8">
        <h2 class="font-display text-xl/7 font-semibold text-white">Achievements</h2>
        <a href="#" class="text-sm/6 font-semibold text-indigo-400">View all</a>
      </header>
      <nav class="px-4 py-4 sm:px-6 sm:py-6 lg:px-8" aria-label="Progress">
        <ol role="list" class="space-y-6">
          <%= for step <- @steps do %>
            <li>
              <%= case step.status do %>
                <% :completed -> %>
                  <a href="#" class="group">
                    <span class="flex items-start">
                      <span class="relative flex h-5 w-5 flex-shrink-0 items-center justify-center">
                        <svg
                          class="h-full w-full text-emerald-400 group-hover:text-emerald-300"
                          viewBox="0 0 20 20"
                          fill="currentColor"
                          aria-hidden="true"
                          data-slot="icon"
                        >
                          <path
                            fill-rule="evenodd"
                            d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                            clip-rule="evenodd"
                          />
                        </svg>
                      </span>
                      <span class="ml-3 text-sm font-medium text-emerald-400 group-hover:text-gray-300">
                        <%= step.name %>
                      </span>
                    </span>
                  </a>
                <% :current -> %>
                  <a href="#" class="flex items-start" aria-current="step">
                    <span
                      class="relative flex h-5 w-5 flex-shrink-0 items-center justify-center"
                      aria-hidden="true"
                    >
                      <span class="absolute h-4 w-4 rounded-full bg-indigo-200"></span>
                      <span class="relative block h-2 w-2 rounded-full bg-indigo-600"></span>
                    </span>
                    <span class="ml-3 text-sm font-medium text-indigo-600"><%= step.name %></span>
                  </a>
                <% :upcoming -> %>
                  <a href="#" class="group">
                    <div class="flex items-start">
                      <div
                        class="relative flex h-5 w-5 flex-shrink-0 items-center justify-center"
                        aria-hidden="true"
                      >
                        <div class="h-2 w-2 rounded-full bg-gray-600 group-hover:bg-gray-500"></div>
                      </div>
                      <p class="ml-3 text-sm font-medium text-gray-400 group-hover:text-gray-300">
                        <%= step.name %>
                      </p>
                    </div>
                  </a>
              <% end %>
            </li>
          <% end %>
        </ol>
      </nav>

      <header class="flex items-center justify-between px-4 pt-4 sm:px-6 sm:pt-6 lg:px-8">
        <h2 class="font-display text-xl/7 font-semibold text-white">Activity feed</h2>
        <a href="#" class="text-sm/6 font-semibold text-indigo-400">View all</a>
      </header>
      <ul class="px-4 py-4 sm:px-6 sm:py-6 lg:px-8">
        <li class="relative pb-8">
          <div>
            <div class="relative -ml-[2.75rem]">
              <span
                class="absolute -bottom-6 left-6 h-5 w-0.5 ml-[2.75rem] bg-gray-200 transition-opacity dark:bg-gray-600 opacity-100"
                aria-hidden="true"
              >
              </span>
              <a class="group inline-flex ml-[2.75rem]" href="/org/grit">
                <div class="relative flex space-x-3">
                  <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                    <div class="flex items-center gap-4">
                      <div class="relative flex -space-x-1">
                        <div class="relative flex-shrink-0 overflow-hidden flex h-12 w-12 items-center justify-center rounded-xl">
                          <img
                            alt="Grit"
                            loading="lazy"
                            decoding="async"
                            data-nimg="fill"
                            src="https://avatars.githubusercontent.com/u/62914393?s=200&amp;v=4"
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </div>
                      </div>
                      <div class="z-10 flex gap-2">
                        <span class="font-emoji text-sm sm:text-xl">💎</span>
                        <div class="space-y-0.5">
                          <p class="text-xs text-gray-500 transition-colors dark:text-gray-200 dark:group-hover:text-white sm:text-base">
                            <strong class="font-bold">Grit</strong>
                            shared <strong class="font-bold">2</strong>
                            bounties rewarding <strong class="font-bold">$300</strong>
                          </p>
                          <div class="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400 sm:text-sm">
                            <time datetime="2024-10-28T20:02:22.464Z">1 day ago</time>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </a>
            </div>
          </div>
        </li>
        <li class="relative pb-8">
          <div>
            <div class="relative -ml-[2.75rem]">
              <span
                class="absolute -bottom-6 left-6 h-5 w-0.5 ml-[2.75rem] bg-gray-200 transition-opacity dark:bg-gray-600 opacity-100"
                aria-hidden="true"
              >
              </span>
              <a class="group inline-flex ml-[2.75rem]" href="/org/Permitio">
                <div class="relative flex space-x-3">
                  <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                    <div class="flex items-center gap-4">
                      <div class="relative flex -space-x-1">
                        <div class="relative flex-shrink-0 overflow-hidden flex h-12 w-12 items-center justify-center rounded-xl">
                          <img
                            alt="Permit.io"
                            loading="lazy"
                            decoding="async"
                            data-nimg="fill"
                            src="https://console.algora.io/asset/storage/v1/object/public/images/org/cm17ongdt0001l603xo4kyvra-1726653932317"
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </div>
                      </div>
                      <div class="z-10 flex gap-2">
                        <span class="font-emoji text-sm sm:text-xl">💎</span>
                        <div class="space-y-0.5">
                          <p class="text-xs text-gray-500 transition-colors dark:text-gray-200 dark:group-hover:text-white sm:text-base">
                            <strong class="font-bold">Permit.io</strong>
                            shared <strong class="font-bold">9</strong>
                            bounties rewarding <strong class="font-bold">$1,850</strong>
                          </p>
                          <div class="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400 sm:text-sm">
                            <time datetime="2024-10-28T15:55:29.178Z">1 day ago</time>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </a>
            </div>
          </div>
        </li>
        <li class="relative pb-8">
          <div>
            <div class="relative -ml-[2.75rem]">
              <span
                class="absolute -bottom-6 left-6 h-5 w-0.5 ml-[2.75rem] bg-gray-200 transition-opacity dark:bg-gray-600 opacity-100"
                aria-hidden="true"
              >
              </span>
              <a class="group inline-flex" href="https://github.com/algora-io/tv/issues/105">
                <div class="relative flex space-x-3">
                  <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                    <div class="flex items-center gap-4">
                      <div class="relative flex -space-x-1">
                        <div class="relative flex-shrink-0 overflow-hidden flex h-12 w-12 items-center justify-center rounded-xl">
                        </div>
                        <div class="relative flex-shrink-0 overflow-hidden flex h-12 w-12 items-center justify-center rounded-xl">
                          <img
                            alt="urbit-pilled"
                            loading="lazy"
                            decoding="async"
                            data-nimg="fill"
                            src="https://console.algora.io/asset/storage/v1/object/public/images/org/clcq81tsi0001mj08ikqffh87-1715034576051"
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </div>
                      </div>
                      <div class="z-10 flex gap-2">
                        <span class="font-emoji text-sm sm:text-xl">💰</span>
                        <div class="space-y-0.5">
                          <p class="text-xs text-gray-500 transition-colors dark:text-gray-200 dark:group-hover:text-white sm:text-base">
                            <strong class="font-bold">Algora</strong>
                            awarded <strong class="font-bold">urbit-pilled</strong>
                            a <strong class="font-bold">$200</strong>
                            bounty
                          </p>
                          <div class="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400 sm:text-sm">
                            <time datetime="2024-10-28T14:23:26.505Z">1 day ago</time>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </a>
            </div>
          </div>
        </li>
        <li class="relative pb-8">
          <div>
            <div class="relative -ml-[2.75rem]">
              <span
                class="absolute -bottom-6 left-6 h-5 w-0.5 ml-[2.75rem] bg-gray-200 transition-opacity dark:bg-gray-600 opacity-100"
                aria-hidden="true"
              >
              </span>
              <a class="group inline-flex ml-[2.75rem]" href="https://tv.algora.io/cmgriffing">
                <div class="relative flex space-x-3">
                  <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                    <div class="flex items-center gap-4">
                      <div class="relative flex -space-x-1">
                        <div class="relative flex-shrink-0 overflow-hidden flex h-12 w-12 items-center justify-center rounded-xl">
                          <img
                            alt="Chris Griffing"
                            loading="lazy"
                            decoding="async"
                            data-nimg="fill"
                            src="https://avatars.githubusercontent.com/u/1195435?v=4"
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </div>
                      </div>
                      <div class="z-10 flex gap-2">
                        <span class="font-emoji text-sm sm:text-xl">🔴</span>
                        <div class="space-y-0.5">
                          <p class="text-xs text-gray-500 transition-colors dark:text-gray-200 dark:group-hover:text-white sm:text-base">
                            <strong class="font-bold">Chris Griffing</strong> started streaming
                          </p>
                          <div class="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400 sm:text-sm">
                            <time datetime="2024-10-27T21:38:00.560Z">2 days ago</time>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </a>
            </div>
          </div>
        </li>
        <li class="relative pb-8">
          <div>
            <div class="relative -ml-[2.75rem]">
              <span
                class="absolute -bottom-6 left-6 h-5 w-0.5 ml-[2.75rem] bg-gray-200 transition-opacity dark:bg-gray-600 opacity-100"
                aria-hidden="true"
              >
              </span>
              <a class="group inline-flex ml-[2.75rem]" href="https://tv.algora.io/danielroe">
                <div class="relative flex space-x-3">
                  <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                    <div class="flex items-center gap-4">
                      <div class="relative flex -space-x-1">
                        <div class="relative flex-shrink-0 overflow-hidden flex h-12 w-12 items-center justify-center rounded-xl">
                          <img
                            alt="Daniel Roe"
                            loading="lazy"
                            decoding="async"
                            data-nimg="fill"
                            src="https://avatars.githubusercontent.com/u/28706372?v=4"
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </div>
                      </div>
                      <div class="z-10 flex gap-2">
                        <span class="font-emoji text-sm sm:text-xl">🔴</span>
                        <div class="space-y-0.5">
                          <p class="text-xs text-gray-500 transition-colors dark:text-gray-200 dark:group-hover:text-white sm:text-base">
                            <strong class="font-bold">Daniel Roe</strong> started streaming
                          </p>
                          <div class="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400 sm:text-sm">
                            <time datetime="2024-10-24T10:32:01.550Z">5 days ago</time>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </a>
            </div>
          </div>
        </li>
      </ul>
    </aside>
    """
  end
end
