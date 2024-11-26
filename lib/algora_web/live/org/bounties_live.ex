defmodule AlgoraWeb.Org.BountiesLive do
  use AlgoraWeb, :live_view

  alias Algora.Bounties

  on_mount AlgoraWeb.Org.BountyHook

  def mount(_params, _session, socket) do
    bounties = Bounties.list_bounties(owner_id: socket.assigns.current_org.id, limit: 10)
    claims = []

    {:ok,
     socket
     |> assign(:bounties, bounties)
     |> assign(:claims, claims)
     |> assign(:open_count, length(bounties))
     |> assign(:completed_count, 0)
     |> assign(:new_bounty_form, to_form(%{"github_issue_url" => "", "amount" => ""}))}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl p-6">
      <div class="mb-6">
        <div class="flex flex-wrap items-start justify-between gap-4 lg:flex-nowrap">
          <div>
            <h2 class="text-2xl font-bold dark:text-white">Bounties</h2>
            <p class="text-sm dark:text-gray-300">
              Create new bounties using the
              <code class="text-base font-semibold text-cyan-300">
                <span>/bounty</span> <span class="text-emerald-300">$AMOUNT</span>
              </code>
              command on Github.
            </p>
          </div>
          <div class="pb-4 md:pb-0">
            <!-- Tab buttons for Open and Completed bounties -->
            <div dir="ltr" data-orientation="horizontal">
              <div
                role="tablist"
                aria-orientation="horizontal"
                class="items-center justify-center rounded-md p-1 dark:bg-gray-800 dark:text-gray-400 -ml-1 grid h-full w-full grid-cols-2 gap-1 bg-white/5 text-white/50"
                tabindex="0"
                data-orientation="horizontal"
                style="outline: none;"
              >
                <button
                  type="button"
                  role="tab"
                  aria-selected="true"
                  class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium data-[state=active]:bg-indigo-600 data-[state=active]:text-white"
                  data-state="active"
                >
                  <div class="relative flex items-center gap-2.5 text-sm md:text-base">
                    <div class="truncate">Open</div>
                    <span class="min-w-[1ch] font-mono transition duration-300 ease-out text-indigo-200">
                      <%= @open_count %>
                    </span>
                  </div>
                </button>
                <button
                  type="button"
                  role="tab"
                  aria-selected="false"
                  class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium hover:bg-indigo-600/50"
                  data-state="inactive"
                >
                  <div class="relative flex items-center gap-2.5 text-sm md:text-base">
                    <div class="truncate">Completed</div>
                    <span class="min-w-[1ch] font-mono transition duration-300 ease-out text-gray-400 group-hover:text-indigo-200">
                      <%= @completed_count %>
                    </span>
                  </div>
                </button>
              </div>
            </div>
            <!-- Checkboxes for hiding claimed and attempted bounties -->
            <div class="mt-3 flex items-center space-x-4">
              <div class="flex items-center space-x-4">
                <div class="flex items-center space-x-2">
                  <input
                    type="checkbox"
                    id="hide-claimed"
                    class="h-6 w-6 rounded-sm border bg-gray-600"
                  />
                  <label for="hide-claimed" class="text-sm font-medium leading-none">
                    Hide claimed
                  </label>
                </div>
                <div class="flex items-center space-x-2">
                  <input
                    type="checkbox"
                    id="hide-attempted"
                    class="h-6 w-6 rounded-sm border bg-gray-600"
                  />
                  <label for="hide-attempted" class="text-sm font-medium leading-none">
                    Hide attempted
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="overflow-hidden rounded-xl border border-white/15">
        <div class="scrollbar-thin w-full overflow-auto">
          <table class="w-full caption-bottom text-sm">
            <tbody class="[&_tr:last-child]:border-0">
              <%= for bounty  <- @bounties do %>
                <tr
                  class="border-b transition-colors hover:bg-gray-100/50 data-[state=selected]:bg-gray-100 dark:data-[state=selected]:bg-gray-800 border-white/15 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] dark:hover:bg-white/[2%]"
                  data-state="false"
                >
                  <td class="p-4 align-middle [&:has([role=checkbox])]:pr-0">
                    <div class="min-w-[250px]">
                      <div class="group relative flex h-full flex-col">
                        <div class="relative h-full pl-2">
                          <div class="flex items-start justify-between">
                            <div class="font-mono text-2xl cursor-pointer">
                              <div class="font-extrabold text-emerald-300 hover:text-emerald-200">
                                $<%= bounty.amount %>
                              </div>
                            </div>
                          </div>
                          <.link
                            rel="noopener"
                            class="inline-flex flex-col group/issue"
                            href={"https://github.com/#{bounty.ticket.owner}/#{bounty.ticket.repo}/issues/#{bounty.ticket.number}"}
                          >
                            <div class="flex items-center gap-4">
                              <div class="truncate">
                                <p class="truncate text-sm font-medium text-gray-300 group-hover/issue:text-gray-200 group-hover/issue:underline">
                                  <%= bounty.ticket.owner %>/<%= bounty.ticket.repo %>#<%= bounty.ticket.number %>
                                </p>
                              </div>
                            </div>
                            <p class="line-clamp-2 break-words text-base font-medium leading-tight text-gray-100 group-hover/issue:text-white group-hover/issue:underline">
                              <%= bounty.ticket.title %>
                            </p>
                          </.link>
                          <p class="flex items-center gap-1.5 text-xs text-gray-400">
                            <%= Algora.Util.time_ago(bounty.inserted_at) %>
                          </p>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="p-4 align-middle [&:has([role=checkbox])]:pr-0">
                    <%= if length(@claims) > 0 do %>
                      <div class="group flex cursor-pointer flex-col items-center gap-1">
                        <div class="flex cursor-pointer justify-center -space-x-3">
                          <%= for claim <- @claims do %>
                            <div class="relative h-10 w-10 flex-shrink-0 rounded-full ring-4 ring-gray-800 group-hover:brightness-110">
                              <img
                                alt={claim.user.username}
                                loading="lazy"
                                decoding="async"
                                class="rounded-full"
                                src={claim.user.avatar_url}
                                style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                              />
                            </div>
                          <% end %>
                        </div>
                        <div class="flex items-center gap-0.5">
                          <div class="whitespace-nowrap text-sm font-medium text-gray-300 group-hover:text-gray-100">
                            <%= length(@claims) %> <%= if length(@claims) == 1,
                              do: "claim",
                              else: "claims" %>
                          </div>
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
                            class="-mr-4 h-4 w-4 text-gray-400 group-hover:text-gray-300 rotate-90"
                          >
                            <path d="M9 6l6 6l-6 6"></path>
                          </svg>
                        </div>
                      </div>
                    <% end %>
                  </td>
                  <td class="p-4 align-middle [&:has([role=checkbox])]:pr-0">
                    <div class="min-w-[180px]">
                      <div class="flex items-center justify-end gap-2">
                        <!-- Add action buttons here (edit, delete, menu) -->
                      </div>
                    </div>
                  </td>
                </tr>
                <%= for claim <- @claims do %>
                  <tr
                    class="border-b transition-colors hover:bg-gray-100/50 data-[state=selected]:bg-gray-100 dark:data-[state=selected]:bg-gray-800 border-white/15 bg-gray-950/50 dark:hover:bg-gray-950/50"
                    data-state="false"
                  >
                    <td class="p-4 align-middle [&:has([role=checkbox])]:pr-0">
                      <div class="min-w-[250px]">
                        <div class="flex items-center gap-3">
                          <div class="flex -space-x-3">
                            <div class="relative h-10 w-10 flex-shrink-0 rounded-full ring-4 ring-gray-800">
                              <img
                                alt={claim.user.username}
                                loading="lazy"
                                decoding="async"
                                class="rounded-full"
                                src={claim.user.avatar_url}
                                style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                              />
                            </div>
                          </div>
                          <div>
                            <div class="text-sm font-medium text-gray-200">
                              <%= claim.user.username %>
                            </div>
                            <div class="text-xs text-gray-400">
                              <%= Algora.Util.time_ago(claim.inserted_at) %>
                            </div>
                          </div>
                        </div>
                      </div>
                    </td>
                    <td class="p-4 align-middle [&:has([role=checkbox])]:pr-0"></td>
                    <td class="p-4 align-middle [&:has([role=checkbox])]:pr-0">
                      <div class="min-w-[180px]">
                        <div class="flex items-center justify-end gap-4">
                          <.link
                            rel="noopener"
                            class="inline-flex items-center justify-center rounded-md text-sm font-medium bg-gray-100 text-gray-900 hover:bg-gray-100/80 dark:bg-white/15 dark:text-gray-50 dark:hover:bg-white/20 h-10 px-4 py-2"
                            href={claim.pull_request_url}
                          >
                            View
                          </.link>
                          <.link
                            class="inline-flex items-center justify-center rounded-md text-sm font-medium bg-indigo-600 text-white hover:bg-indigo-600/90 h-10 px-4 py-2"
                            navigate={~p"/org/#{@current_org.handle}/checkout?claims=#{claim.id}"}
                          >
                            Reward
                          </.link>
                        </div>
                      </div>
                    </td>
                  </tr>
                <% end %>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
