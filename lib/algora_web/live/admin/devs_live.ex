defmodule AlgoraWeb.Admin.DevsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    # Define available options
    available_techs = Enum.take(AlgoraWeb.Components.TechBadge.langs(), 33)
    available_countries = Enum.sort(Algora.PSP.ConnectCountries.list_codes() ++ ["CN"])

    # Start with empty selections
    selected_techs = []
    selected_countries = []

    {:ok,
     socket
     |> assign(:page_title, "Developers")
     |> assign(:available_techs, available_techs)
     |> assign(:available_countries, available_countries)
     |> assign(:selected_techs, selected_techs)
     |> assign(:selected_countries, selected_countries)
     |> assign_matches()}
  end

  @impl true
  def handle_event("toggle_tech", %{"tech" => tech}, socket) do
    selected_techs =
      if tech in socket.assigns.selected_techs do
        List.delete(socket.assigns.selected_techs, tech)
      else
        [tech | socket.assigns.selected_techs]
      end

    {:noreply,
     socket
     |> assign(:selected_techs, selected_techs)
     |> assign_matches()}
  end

  @impl true
  def handle_event("toggle_country", %{"code" => code}, socket) do
    selected_countries =
      if code in socket.assigns.selected_countries do
        List.delete(socket.assigns.selected_countries, code)
      else
        [code | socket.assigns.selected_countries]
      end

    {:noreply,
     socket
     |> assign(:selected_countries, selected_countries)
     |> assign_matches()}
  end

  defp assign_matches(socket) do
    matches =
      [
        tech_stack: socket.assigns.selected_techs,
        limit: 50,
        sort_by: [{"countries", socket.assigns.selected_countries}]
      ]
      |> Algora.Cloud.list_top_matches()
      |> Algora.Settings.load_matches_2()

    socket
    |> assign(:matches, matches)
    |> assign(
      :contributions_map,
      matches |> Enum.map(& &1.user) |> fetch_applicants_contributions(socket.assigns.selected_techs)
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-8 p-4 sm:p-6 lg:p-8">
      <.section title="Developers">
        <h3 class="pt-4 text-sm font-semibold text-foreground">Tech stack</h3>
        <div class="flex items-center flex-wrap gap-4 pt-4">
          <%= for tech <- @available_techs do %>
            <.tech_badge
              class="cursor-pointer"
              phx-click="toggle_tech"
              phx-value-tech={tech}
              tech={tech}
              variant={if tech in @selected_techs, do: "success", else: "outline"}
            />
          <% end %>
        </div>
        <h3 class="pt-8 text-sm font-semibold text-foreground">Countries</h3>
        <div class="flex items-center flex-wrap gap-4 pt-4">
          <%= for code <- @available_countries do %>
            <.badge
              class="cursor-pointer"
              phx-click="toggle_country"
              phx-value-code={code}
              variant={if code in @selected_countries, do: "success", else: "outline"}
            >
              {Algora.Misc.CountryEmojis.get(code)} {code}
            </.badge>
          <% end %>
        </div>

        <div class="pt-8 grid grid-cols-1 gap-4 lg:grid-cols-3">
          <%= for match <- @matches do %>
            <div>
              <.match_card
                user={match.user}
                tech_stack={@selected_techs |> Enum.take(1)}
                contributions={Map.get(@contributions_map, match.user.id, [])}
                contract_type="bring_your_own"
              />
            </div>
          <% end %>
        </div>
      </.section>
    </div>
    """
  end

  defp match_card(assigns) do
    ~H"""
    <div class="h-full relative border ring-1 ring-transparent hover:ring-border transition-all bg-card group rounded-xl text-card-foreground shadow p-6">
      <%= if @user.provider_meta["hireable"] do %>
        <div class="absolute top-0 right-0">
          <.badge variant="success">
            Hireable
          </.badge>
        </div>
      <% end %>
      <div class="w-full">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div class="flex gap-4 truncate">
            <.link navigate={User.url(@user)}>
              <.avatar class="h-12 w-12 rounded-full">
                <.avatar_image src={@user.avatar_url} alt={@user.name} />
                <.avatar_fallback class="rounded-lg">
                  {Algora.Util.initials(@user.name)}
                </.avatar_fallback>
              </.avatar>
            </.link>

            <div class="truncate w-full">
              <div class="flex items-center gap-1 text-base text-foreground">
                <.link navigate={User.url(@user)} class="font-semibold hover:underline">
                  {@user.name}
                  <span :if={@user.country}>
                    {Algora.Misc.CountryEmojis.get(@user.country)}
                  </span>
                </.link>
              </div>
              <div
                :if={@user.provider_meta["company"]}
                class="flex group-hover:hidden items-center gap-1 font-semibold text-sm text-muted-foreground"
              >
                {@user.provider_meta["company"] |> String.trim_leading("https://")}
              </div>
              <div
                :if={@user.provider_meta}
                class="hidden group-hover:flex pt-0.5 items-center gap-x-2 gap-y-2 text-xs text-muted-foreground truncate"
              >
                <.link
                  :if={@user.provider_login}
                  href={"https://github.com/#{@user.provider_login}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <.icon name="github" class="shrink-0 h-4 w-4" />
                </.link>
                <.link
                  :if={@user.provider_meta["twitter_username"]}
                  href={"https://x.com/#{@user.provider_meta["twitter_username"]}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <.icon name="tabler-brand-x" class="shrink-0 h-4 w-4" />
                </.link>
                <div :if={@user.provider_meta["location"]} class="flex items-center gap-1 truncate">
                  <.icon name="tabler-map-pin" class="shrink-0 h-4 w-4" />
                  <span class="truncate">
                    {@user.provider_meta["location"]}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div :if={@contributions != []} class="mt-4">
          <p class="text-xs text-muted-foreground uppercase font-semibold">
            Top contributions
          </p>
          <div class="flex flex-col gap-3 mt-2">
            <%= for {owner, contributions} <- aggregate_contributions(@contributions) |> Enum.take(3) do %>
              <.link
                href={"https://github.com/#{owner.provider_login}/#{List.first(contributions).repository.name}/pulls?q=author%3A#{@user.provider_login}+is%3Amerged+"}
                target="_blank"
                rel="noopener"
                class="flex items-center gap-3 rounded-xl pr-2 bg-card/50 border border-border/50 hover:border-border transition-all"
              >
                <img
                  src={owner.avatar_url}
                  class="h-12 w-12 rounded-xl rounded-r-none md:saturate-0 group-hover:saturate-100 transition-all"
                  alt={owner.name}
                />
                <div class="w-full flex flex-col text-xs font-medium gap-0.5">
                  <span class="flex items-start justify-between gap-5">
                    <span class="font-display">
                      {if owner.type == :organization do
                        owner.name
                      else
                        List.first(contributions).repository.name
                      end}
                    </span>
                    <%= if tech = List.first(contributions).repository.tech_stack |> List.first() do %>
                      <.tech_badge
                        variant="ghost"
                        class="saturate-0 text-[11px] group-hover:saturate-100 transition-all"
                        tech={tech}
                      />
                    <% end %>
                  </span>
                  <div class="flex items-center gap-2 font-semibold">
                    <span class="flex items-center text-amber-300 text-xs">
                      <.icon name="tabler-star-filled" class="h-4 w-4 mr-1" />
                      {Algora.Util.format_number_compact(
                        max(owner.stargazers_count, total_stars(contributions))
                      )}
                    </span>
                    <span class="flex items-center text-purple-400 text-xs">
                      <.icon name="tabler-git-pull-request" class="h-4 w-4 mr-1" />
                      {Algora.Util.format_number_compact(total_contributions(contributions))}
                    </span>
                  </div>
                </div>
              </.link>
            <% end %>
          </div>
        </div>

        <div
          :if={@user.provider_meta["bio"]}
          class="mt-4 font-medium text-sm text-muted-foreground line-clamp-3"
        >
          {@user.provider_meta["bio"]}
        </div>
      </div>
    </div>
    """
  end

  defp total_stars(contributions) do
    contributions
    |> Enum.map(& &1.repository.stargazers_count)
    |> Enum.sum()
  end

  defp total_contributions(contributions) do
    contributions
    |> Enum.map(& &1.contribution_count)
    |> Enum.sum()
  end

  defp aggregate_contributions(contributions) do
    groups = Enum.group_by(contributions, fn c -> c.repository.user end)

    contributions
    |> Enum.map(fn c -> {c.repository.user, groups[c.repository.user]} end)
    |> Enum.uniq_by(fn {owner, _} -> owner.id end)
  end

  defp fetch_applicants_contributions(users, tech_stack) do
    users
    |> Enum.map(& &1.id)
    |> Algora.Workspace.list_user_contributions(tech_stack: tech_stack)
    |> Enum.group_by(& &1.user.id)
  end
end
