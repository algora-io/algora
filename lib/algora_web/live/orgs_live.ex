defmodule AlgoraWeb.OrgsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Organizations

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    query_opts = [limit: page_size()]

    {:ok,
     socket
     |> assign(:query_opts, query_opts)
     |> assign_orgs()}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    %{orgs: orgs} = socket.assigns
    last_org = List.last(orgs)

    more_orgs =
      Organizations.list_orgs(
        Keyword.put(socket.assigns.query_opts, :before, %{
          priority: last_org.priority,
          stargazers_count: last_org.stargazers_count,
          id: last_org.id
        })
      )

    {:noreply,
     socket
     |> assign(:orgs, orgs ++ more_orgs)
     |> assign(:has_more_orgs, length(more_orgs) >= page_size())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6">
      <.section title="Projects" subtitle="Meet the projects on Algora">
        <div id="orgs-container" phx-hook="InfiniteScroll">
          <ul class="flex flex-col gap-8 md:grid md:grid-cols-2 xl:grid-cols-3">
            <%= for org <- @orgs do %>
              <li>
                <.link navigate={~p"/org/#{org.handle}"}>
                  <div class="group/card from-white/[2%] via-white/[2%] to-white/[2%] bg-purple-200/[5%] relative h-full rounded-xl border border-white/10 bg-gradient-to-br hover:bg-purple-200/[7.5%] hover:border-white/15 md:gap-8">
                    <div class="pointer-events-none">
                      <div class="[mask-image:linear-gradient(black,transparent)] absolute inset-0 z-0 opacity-0 group-hover/card:opacity-100">
                      </div>
                      <div
                        class="via-white/[2%] absolute inset-0 z-10 bg-gradient-to-br opacity-0 group-hover/card:opacity-100"
                        style="mask-image: radial-gradient(240px at 476px 41.4px, white, transparent);"
                      >
                      </div>
                      <div
                        class="absolute inset-0 z-10 opacity-0 mix-blend-overlay group-hover/card:opacity-100"
                        style="mask-image: radial-gradient(240px at 476px 41.4px, white, transparent);"
                      >
                      </div>
                    </div>
                    <div class="relative flex flex-col items-center overflow-hidden px-5 py-6">
                      <span class="relative flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-full sm:h-24 sm:w-24">
                        <img class="aspect-square h-full w-full" alt={org.name} src={org.avatar_url} />
                      </span>
                      <div class="flex flex-col items-center gap-2 pt-2 text-center">
                        <div>
                          <span class="block text-lg font-semibold text-white sm:text-xl">
                            {org.name}
                          </span>

                          <div class="flex flex-wrap items-center justify-center gap-x-3 gap-y-1 pt-1 text-xs text-gray-300 sm:text-sm">
                            <.link
                              :if={org.provider_login}
                              href={"https://github.com/#{org.provider_login}"}
                              rel="noopener"
                              class="flex items-center gap-1"
                            >
                              <.icon name="tabler-brand-github" class="h-4 w-4" />
                            </.link>
                            <.link
                              :if={org.twitter_url}
                              href={org.twitter_url}
                              rel="noopener"
                              class="flex items-center gap-1"
                            >
                              <.icon name="tabler-brand-twitter" class="h-4 w-4" />
                            </.link>
                            <.link
                              :if={org.discord_url}
                              href={org.discord_url}
                              rel="noopener"
                              class="flex items-center gap-1"
                            >
                              <.icon name="tabler-brand-discord" class="h-4 w-4" />
                            </.link>
                            <.link
                              :if={org.website_url}
                              href={org.website_url}
                              rel="noopener"
                              class="flex items-center gap-1"
                            >
                              <.icon name="tabler-world" class="h-4 w-4" />
                            </.link>
                          </div>

                          <span class="line-clamp-3 pt-2 text-xs text-gray-300 sm:text-sm">
                            {org.bio}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                </.link>
              </li>
            <% end %>
          </ul>
          <div :if={@has_more_orgs} class="flex justify-center mt-4" id="load-more-indicator">
            <div class="animate-pulse text-muted-foreground">
              <.icon name="tabler-loader" class="h-6 w-6 animate-spin" />
            </div>
          </div>
        </div>
      </.section>
    </div>
    """
  end

  defp assign_orgs(socket) do
    orgs = Organizations.list_orgs(socket.assigns.query_opts)

    socket
    |> assign(:orgs, orgs)
    |> assign(:has_more_orgs, length(orgs) >= page_size())
  end

  defp page_size, do: 9
end
