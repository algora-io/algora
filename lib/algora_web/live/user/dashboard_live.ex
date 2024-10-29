defmodule AlgoraWeb.User.DashboardLive do
  use AlgoraWeb, :live_view
  alias Algora.Bounties
  alias Algora.Money

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:tech_stack, ["Elixir", "TypeScript"])
      |> assign(:bounties, Bounties.list_bounties(status: :open, limit: 10))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="p-4 pt-6 sm:p-6 md:p-8">
      <div dir="ltr" data-orientation="horizontal">
        <div class="flex flex-wrap items-end justify-between gap-3 md:pl-4">
          <h2 class="font-display text-2xl font-bold dark:text-white">Bounties for you</h2>
          <div
            role="tablist"
            aria-orientation="horizontal"
            class="h-10 items-center justify-center rounded-md p-1 dark:bg-gray-800 dark:text-gray-400 grid w-full grid-cols-4 gap-1 bg-white/5 text-white/50 sm:max-w-[25rem]"
            tabindex="0"
            data-orientation="horizontal"
            style="outline: none;"
          >
            <button
              type="button"
              role="tab"
              aria-selected="true"
              aria-controls="radix-:r0:-content-bounties"
              data-state="active"
              id="radix-:r0:-trigger-bounties"
              class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-white transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:shadow-sm dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800 dark:data-[state=active]:bg-indigo-600 dark:data-[state=active]:text-gray-50 hover:bg-indigo-600/50 data-[state=active]:bg-indigo-600 data-[state=active]:text-white"
              tabindex="-1"
              data-orientation="horizontal"
              data-radix-collection-item=""
            >
              Bounties
            </button>
            <button
              type="button"
              role="tab"
              aria-selected="false"
              aria-controls="radix-:r0:-content-orgs"
              data-state="inactive"
              id="radix-:r0:-trigger-orgs"
              class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-white transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:shadow-sm dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800 dark:data-[state=active]:bg-indigo-600 dark:data-[state=active]:text-gray-50 hover:bg-indigo-600/50 data-[state=active]:bg-indigo-600 data-[state=active]:text-white"
              tabindex="-1"
              data-orientation="horizontal"
              data-radix-collection-item=""
            >
              Projects
            </button>
            <button
              type="button"
              role="tab"
              aria-selected="false"
              aria-controls="radix-:r0:-content-rewarded"
              data-state="inactive"
              id="radix-:r0:-trigger-rewarded"
              class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-white transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:shadow-sm dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800 dark:data-[state=active]:bg-indigo-600 dark:data-[state=active]:text-gray-50 hover:bg-indigo-600/50 data-[state=active]:bg-indigo-600 data-[state=active]:text-white"
              tabindex="-1"
              data-orientation="horizontal"
              data-radix-collection-item=""
            >
              Awards
            </button>
            <button
              type="button"
              role="tab"
              aria-selected="false"
              aria-controls="radix-:r0:-content-community"
              data-state="inactive"
              id="radix-:r0:-trigger-community"
              class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-white transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-400 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:shadow-sm dark:ring-offset-indigo-600 dark:focus-visible:ring-gray-800 dark:data-[state=active]:bg-indigo-600 dark:data-[state=active]:text-gray-50 hover:bg-indigo-600/50 data-[state=active]:bg-indigo-600 data-[state=active]:text-white"
              tabindex="-1"
              data-orientation="horizontal"
              data-radix-collection-item=""
            >
              Community
            </button>
          </div>
        </div>
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
    """
  end
end
