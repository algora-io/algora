defmodule AlgoraWeb.Org.BountiesLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Bounties
  alias Algora.Bounties.Bounty

  on_mount AlgoraWeb.Org.BountyHook

  def mount(_params, _session, socket) do
    open_bounties = Bounties.list_bounties(owner_id: socket.assigns.current_org.id, limit: 10, status: :open)
    paid_bounties = Bounties.list_bounties(owner_id: socket.assigns.current_org.id, limit: 10, status: :paid)

    # TODO:
    claims = []

    {:ok,
     socket
     |> assign(:open_bounties, open_bounties)
     |> assign(:paid_bounties, paid_bounties)
     |> assign(:claims, claims)
     |> assign(:open_count, length(open_bounties))
     |> assign(:completed_count, length(paid_bounties))
     |> assign(:new_bounty_form, to_form(%{"github_issue_url" => "", "amount" => ""}))}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto p-6">
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
                class="-ml-1 grid h-full w-full grid-cols-2 items-center justify-center gap-1 rounded-md bg-white/5 p-1 text-white/50 dark:bg-gray-800 dark:text-gray-400"
                tabindex="0"
                data-orientation="horizontal"
                style="outline: none;"
              >
                <button
                  type="button"
                  role="tab"
                  aria-selected={@current_tab == :open}
                  class={"inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium #{if @current_tab == :open, do: "bg-indigo-600 text-white", else: "hover:bg-indigo-600/50"}"}
                  data-state={if @current_tab == :open, do: "active", else: "inactive"}
                  phx-click="change-tab"
                  phx-value-tab="open"
                >
                  <div class="relative flex items-center gap-2.5 text-sm md:text-base">
                    <div class="truncate">Open</div>
                    <span class="min-w-[1ch] font-mono text-indigo-200 transition duration-300 ease-out">
                      {@open_count}
                    </span>
                  </div>
                </button>
                <button
                  type="button"
                  role="tab"
                  aria-selected={@current_tab == :completed}
                  class={"inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium #{if @current_tab == :completed, do: "bg-indigo-600 text-white", else: "hover:bg-indigo-600/50"}"}
                  data-state={if @current_tab == :completed, do: "active", else: "inactive"}
                  phx-click="change-tab"
                  phx-value-tab="completed"
                >
                  <div class="relative flex items-center gap-2.5 text-sm md:text-base">
                    <div class="truncate">Completed</div>
                    <span class="min-w-[1ch] font-mono text-gray-400 transition duration-300 ease-out group-hover:text-indigo-200">
                      {@completed_count}
                    </span>
                  </div>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="overflow-hidden rounded-xl border border-white/15">
        <div class="scrollbar-thin w-full overflow-auto">
          <table class="w-full caption-bottom text-sm">
            <tbody class="[&_tr:last-child]:border-0">
              <%= for bounty <- (if @current_tab == :open, do: @open_bounties, else: @paid_bounties) do %>
                <tr
                  class="bg-white/[2%] from-white/[2%] via-white/[2%] to-white/[2%] border-b border-white/15 bg-gradient-to-br transition-colors data-[state=selected]:bg-gray-100 hover:bg-gray-100/50 dark:data-[state=selected]:bg-gray-800 dark:hover:bg-white/[2%]"
                  data-state="false"
                >
                  <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
                    <div class="min-w-[250px]">
                      <div class="group relative flex h-full flex-col">
                        <div class="relative h-full pl-2">
                          <div class="flex items-start justify-between">
                            <div class="cursor-pointer font-mono text-2xl">
                              <div class="font-extrabold text-emerald-300 hover:text-emerald-200">
                                {Money.to_string!(bounty.amount)}
                              </div>
                            </div>
                          </div>
                          <.link
                            rel="noopener"
                            class="group/issue inline-flex flex-col"
                            href={Bounty.url(bounty)}
                          >
                            <div class="flex items-center gap-4">
                              <div class="truncate">
                                <p class="truncate text-sm font-medium text-gray-300 group-hover/issue:text-gray-200 group-hover/issue:underline">
                                  {Bounty.path(bounty)}
                                </p>
                              </div>
                            </div>
                            <p class="line-clamp-2 break-words text-base font-medium leading-tight text-gray-100 group-hover/issue:text-white group-hover/issue:underline">
                              {bounty.ticket.title}
                            </p>
                          </.link>
                          <p class="flex items-center gap-1.5 text-xs text-gray-400">
                            {Algora.Util.time_ago(bounty.inserted_at)}
                          </p>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
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
                            {length(@claims)} {if length(@claims) == 1,
                              do: "claim",
                              else: "claims"}
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
                            class="-mr-4 h-4 w-4 rotate-90 text-gray-400 group-hover:text-gray-300"
                          >
                            <path d="M9 6l6 6l-6 6"></path>
                          </svg>
                        </div>
                      </div>
                    <% end %>
                  </td>
                  <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
                    <div class="min-w-[180px]">
                      <div class="flex items-center justify-end gap-2">
                        <!-- Add action buttons here (edit, delete, menu) -->
                      </div>
                    </div>
                  </td>
                </tr>
                <%= for claim <- @claims do %>
                  <tr
                    class="border-b border-white/15 bg-gray-950/50 transition-colors data-[state=selected]:bg-gray-100 hover:bg-gray-100/50 dark:data-[state=selected]:bg-gray-800 dark:hover:bg-gray-950/50"
                    data-state="false"
                  >
                    <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
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
                              {claim.user.username}
                            </div>
                            <div class="text-xs text-gray-400">
                              {Algora.Util.time_ago(claim.inserted_at)}
                            </div>
                          </div>
                        </div>
                      </div>
                    </td>
                    <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle"></td>
                    <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
                      <div class="min-w-[180px]">
                        <div class="flex items-center justify-end gap-4">
                          <.link
                            rel="noopener"
                            class="inline-flex h-10 items-center justify-center rounded-md bg-gray-100 px-4 py-2 text-sm font-medium text-gray-900 hover:bg-gray-100/80 dark:bg-white/15 dark:text-gray-50 dark:hover:bg-white/20"
                            href={claim.pull_request_url}
                          >
                            View
                          </.link>
                          <.link
                            class="inline-flex h-10 items-center justify-center rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-600/90"
                            href="#"
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

  def handle_event("change-tab", %{"tab" => "completed"}, socket) do
    {:noreply, push_patch(socket, to: ~p"/org/#{socket.assigns.current_org.handle}/bounties?status=completed")}
  end

  def handle_event("change-tab", %{"tab" => "open"}, socket) do
    {:noreply, push_patch(socket, to: ~p"/org/#{socket.assigns.current_org.handle}/bounties?status=open")}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :current_tab, get_current_tab(params))}
  end

  defp get_current_tab(params) do
    case params["status"] do
      "open" -> :open
      "completed" -> :completed
      _ -> :open
    end
  end
end
