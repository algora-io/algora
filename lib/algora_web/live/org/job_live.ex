defmodule AlgoraWeb.Org.JobLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts.User
  alias Algora.Jobs
  alias Algora.Settings

  require Logger

  @impl true
  def mount(%{"org_handle" => handle, "id" => id}, _session, socket) do
    with {:ok, job} <- Jobs.get_job_posting(id),
         {:ok, applicants} <- Jobs.list_job_applications(job) do
      matches = Settings.get_org_matches(job.user)
      imported_applicants = []
      # TODO: Replace with actual subscription check
      has_subscription = false

      # Fetch all contributions for applicants upfront
      contributions_map = fetch_applicants_contributions(applicants)

      # Sort applicants by total contributions
      sorted_applicants = sort_applicants_by_contributions(applicants, contributions_map)

      {:ok,
       socket
       |> assign(:page_title, job.title)
       |> assign(:job, job)
       |> assign(:applicants, sorted_applicants)
       |> assign(:contributions_map, contributions_map)
       |> assign(:total_applicants, length(applicants))
       |> assign(:matches, matches)
       |> assign(:total_matches, length(matches))
       |> assign(:imported_applicants, imported_applicants)
       |> assign(:total_imported, length(imported_applicants))
       |> assign(:has_subscription, has_subscription)}
    else
      _ -> {:ok, push_navigate(socket, to: ~p"/#{handle}/home")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-8 xl:space-y-16 p-4 sm:p-6 lg:p-8">
      <.section>
        <.card class="flex flex-col p-6">
          <div class="flex items-start md:items-center gap-3">
            <.avatar class="h-16 w-16">
              <.avatar_image src={@job.user.avatar_url} />
              <.avatar_fallback>
                {Algora.Util.initials(@job.user.name)}
              </.avatar_fallback>
            </.avatar>
            <div>
              <div class="text-lg text-foreground font-bold font-display">
                {@job.user.name}
              </div>
              <div class="text-sm text-muted-foreground line-clamp-2 md:line-clamp-1">
                {@job.user.bio}
              </div>
              <div class="flex gap-2 items-center">
                <%= for {platform, icon} <- social_links(),
                      url = social_link(@job.user, platform),
                      not is_nil(url) do %>
                  <.link
                    href={url}
                    target="_blank"
                    class="text-muted-foreground hover:text-foreground"
                  >
                    <.icon name={icon} class="size-4" />
                  </.link>
                <% end %>
              </div>
            </div>
          </div>

          <div class="pt-8">
            <div>
              <.link href={@job.url} class="text-lg font-semibold hover:underline" target="_blank">
                {@job.title}
              </.link>
            </div>
            <div :if={@job.description} class="pt-1 text-sm text-muted-foreground">
              {@job.description}
            </div>
            <div class="pt-2 flex flex-wrap gap-2">
              <%= for tech <- @job.tech_stack do %>
                <.badge variant="outline">{tech}</.badge>
              <% end %>
            </div>
          </div>
        </.card>
      </.section>

      <.section title="Matches" subtitle="Top developers matching your requirements">
        <:actions>
          <.button>
            Invite all
          </.button>
        </:actions>
        <%= if Enum.empty?(@matches) do %>
          <.card class="rounded-lg bg-card py-12 text-center lg:rounded-[2rem]">
            <.card_header>
              <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                <.icon name="tabler-users" class="h-8 w-8 text-muted-foreground" />
              </div>
              <.card_title>No matches yet</.card_title>
              <.card_description>
                Matches will appear here once we find developers matching your requirements
              </.card_description>
            </.card_header>
          </.card>
        <% else %>
          <div class="grid grid-cols-1 gap-4 lg:grid-cols-3">
            <%= for {match, index} <- Enum.with_index(@matches) do %>
              <div class={
                if !@has_subscription && index != 0, do: "filter blur-sm pointer-events-none"
              }>
                <.match_card match={match} />
              </div>
            <% end %>
          </div>
        <% end %>
      </.section>

      <.section title="Applicants" subtitle="Developers who applied for this position">
        <:actions>
          <.button variant="secondary" class="ml-auto">
            Import
          </.button>
          <.button variant="default">
            Screen
          </.button>
        </:actions>
        <%= if Enum.empty?(@applicants) do %>
          <.card class="rounded-lg bg-card py-12 text-center lg:rounded-[2rem]">
            <.card_header>
              <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                <.icon name="tabler-users" class="h-8 w-8 text-muted-foreground" />
              </div>
              <.card_title>No applicants yet</.card_title>
              <.card_description>
                Applications will appear here once developers apply
              </.card_description>
            </.card_header>
          </.card>
        <% else %>
          <div class="grid gap-8">
            <%= for {application, _index} <- Enum.with_index(@applicants) do %>
              <div>
                <.developer_card
                  user={application.user}
                  contributions={Map.get(@contributions_map, application.user.id, [])}
                />
              </div>
            <% end %>
          </div>
        <% end %>
      </.section>

      <.section>
        <div class="border ring-1 ring-transparent rounded-xl overflow-hidden">
          <div class="bg-card/75 flex flex-col h-full p-4 rounded-xl border-t-4 sm:border-t-0 sm:border-l-4 border-emerald-400">
            <div class="grid md:grid-cols-2 gap-8 p-4 sm:p-6">
              <div>
                <h3 class="text-2xl font-semibold text-foreground">
                  Unlock Full Hiring
                  <span class="text-success drop-shadow-[0_1px_5px_#34d39980]">Potential</span>
                </h3>
                <div class="pt-1 text-sm text-muted-foreground">
                  Get access to all applicants and GitHub profiles
                </div>
                <ul class="space-y-3 mt-4 text-sm">
                  <li class="flex items-center gap-2">
                    <.icon name="tabler-check" class="h-5 w-5 text-success" />
                    <span>Unlimited job postings</span>
                  </li>
                  <li class="flex items-center gap-2">
                    <.icon name="tabler-check" class="h-5 w-5 text-success" />
                    <span>Access to all applicants and GitHub profiles</span>
                  </li>
                  <li class="flex items-center gap-2">
                    <.icon name="tabler-check" class="h-5 w-5 text-success" />
                    <span>Embeddable job widget for your website</span>
                  </li>
                </ul>
              </div>
              <div class="flex flex-col justify-center items-center text-center">
                <.button phx-click="activate_subscription" size="lg" class="w-full max-w-xs">
                  Activate
                </.button>
              </div>
            </div>
          </div>
        </div>
      </.section>
    </div>
    """
  end

  @impl true
  def handle_event("activate_subscription", _params, socket) do
    case Jobs.create_payment_session(%{socket.assigns.job | email: socket.assigns.current_user.email}) do
      {:ok, url} ->
        Algora.Admin.alert("Payment session created for job posting: #{socket.assigns.job.company_name}", :info)
        {:noreply, redirect(socket, external: url)}

      {:error, reason} ->
        Logger.error("Failed to create payment session: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
    end
  end

  defp developer_card(assigns) do
    ~H"""
    <tr class="border-b transition-colors">
      <td class="py-4 align-middle">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div class="flex items-center gap-4">
            <.link navigate={User.url(@user)}>
              <.avatar class="h-12 w-12 rounded-full">
                <.avatar_image src={@user.avatar_url} alt={@user.name} />
                <.avatar_fallback class="rounded-lg">
                  {Algora.Util.initials(@user.name)}
                </.avatar_fallback>
              </.avatar>
            </.link>

            <div>
              <div class="flex items-center gap-1 text-base text-foreground">
                <.link navigate={User.url(@user)} class="font-semibold hover:underline">
                  {@user.name} {Algora.Misc.CountryEmojis.get(@user.country)}
                </.link>
              </div>
              <div
                :if={@user.provider_meta}
                class="pt-0.5 flex items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm max-w-[250px] 2xl:max-w-none truncate"
              >
                <.link
                  :if={@user.provider_login}
                  href={"https://github.com/#{@user.provider_login}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <.icon name="github" class="shrink-0 h-4 w-4" />
                  <span class="line-clamp-1">{@user.provider_login}</span>
                </.link>
                <.link
                  :if={@user.provider_meta["twitter_handle"]}
                  href={"https://x.com/#{@user.provider_meta["twitter_handle"]}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <.icon name="tabler-brand-x" class="shrink-0 h-4 w-4" />
                  <span class="line-clamp-1">{@user.provider_meta["twitter_handle"]}</span>
                </.link>
                <div :if={@user.provider_meta["location"]} class="flex items-center gap-1">
                  <.icon name="tabler-map-pin" class="shrink-0 h-4 w-4" />
                  <span class="line-clamp-1">{@user.provider_meta["location"]}</span>
                </div>
                <div :if={@user.provider_meta["company"]} class="flex items-center gap-1">
                  <.icon name="tabler-building" class="shrink-0 h-4 w-4" />
                  <span class="line-clamp-1">
                    {@user.provider_meta["company"] |> String.trim_leading("@")}
                  </span>
                </div>
              </div>
            </div>
          </div>
          <div class="flex gap-2">
            <.button
              phx-click="share_opportunity"
              phx-value-user_id={@user.id}
              phx-value-type="bounty"
              variant="outline"
              size="sm"
            >
              Bounty
            </.button>
            <.button
              phx-click="share_opportunity"
              phx-value-user_id={@user.id}
              phx-value-type="tip"
              variant="outline"
              size="sm"
            >
              Interview
            </.button>
            <.button
              phx-click="share_opportunity"
              phx-value-user_id={@user.id}
              phx-value-type="contract"
              variant="outline"
              size="sm"
            >
              Contract
            </.button>
          </div>
        </div>

        <div :if={@contributions != []} class="pl-16 mt-4 space-y-4">
          <div class="flex items-center gap-3 mt-2">
            <%= for {owner, contributions} <- aggregate_contributions(@contributions) do %>
              <.link
                href={"https://github.com/#{owner.provider_login}/#{List.first(contributions).repository.name}/pulls?q=author%3A#{@user.provider_login}+is%3Amerged+"}
                target="_blank"
                rel="noopener"
                class="flex items-center gap-3 group rounded-xl pr-2 bg-card/50 border border-border/50 hover:border-border transition-all"
              >
                <img
                  src={owner.avatar_url}
                  class="h-12 w-12 rounded-xl rounded-r-none saturate-0 group-hover:saturate-100 transition-all"
                  alt={owner.name}
                />
                <div class="flex flex-col text-sm font-medium gap-0.5">
                  <span class="flex items-start gap-5">
                    <span class="font-display">
                      {owner.name}
                    </span>
                    <%= if tech = List.first(List.first(contributions).repository.tech_stack) do %>
                      <span class="flex items-center text-foreground text-[11px] gap-1">
                        <img
                          src={"https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/#{String.downcase(tech)}/#{String.downcase(tech)}-original.svg"}
                          class="w-4 h-4 invert saturate-0"
                        /> {tech}
                      </span>
                    <% end %>
                  </span>
                  <div class="flex items-center gap-2 font-semibold">
                    <span class="flex items-center text-amber-300 text-xs">
                      <.icon name="tabler-star-filled" class="h-4 w-4 mr-1" />
                      {Algora.Util.format_number_compact(
                        if owner.stargazers_count > 0,
                          do: owner.stargazers_count,
                          else: total_stars(contributions)
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
      </td>
    </tr>
    """
  end

  defp match_card(assigns) do
    ~H"""
    <div class="relative flex flex-col lg:flex-row xl:items-center lg:justify-between gap-4 sm:gap-8 lg:gap-4 xl:gap-6 border bg-card rounded-xl text-card-foreground shadow p-6">
      <div class="w-full truncate">
        <div class="flex items-center justify-between gap-4">
          <div class="flex items-start gap-4">
            <.link navigate={User.url(@match.user)}>
              <.avatar class="h-16 w-16 rounded-full">
                <.avatar_image src={@match.user.avatar_url} alt={@match.user.name} />
                <.avatar_fallback class="rounded-lg">
                  {Algora.Util.initials(@match.user.name)}
                </.avatar_fallback>
              </.avatar>
            </.link>

            <div>
              <div class="flex items-center gap-4 text-foreground">
                <.link
                  navigate={User.url(@match.user)}
                  class="text-base sm:text-lg font-semibold hover:underline"
                >
                  {@match.user.name} {Algora.Misc.CountryEmojis.get(@match.user.country)}
                </.link>
              </div>
              <div
                :if={@match.user.provider_meta}
                class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm"
              >
                <.link
                  :if={@match.user.provider_login}
                  href={"https://github.com/#{@match.user.provider_login}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <.icon name="github" class="shrink-0 h-4 w-4" />
                  <span class="line-clamp-1">{@match.user.provider_login}</span>
                </.link>
                <.link
                  :if={@match.user.provider_meta["twitter_handle"]}
                  href={"https://x.com/#{@match.user.provider_meta["twitter_handle"]}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <.icon name="tabler-brand-x" class="shrink-0 h-4 w-4" />
                  <span class="line-clamp-1">{@match.user.provider_meta["twitter_handle"]}</span>
                </.link>
              </div>
              <div class="pt-1.5 flex gap-2 line-clamp-1">
                <%= for tech <- @match.user.tech_stack |> Enum.take(4) do %>
                  <div class="rounded-lg bg-foreground/5 px-2 py-1 text-xs font-medium text-foreground ring-1 ring-inset ring-foreground/25">
                    {tech}
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        <div class="pt-4 text-sm sm:text-base text-muted-foreground font-medium">
          Completed
          <span class="font-semibold font-display text-foreground/80">
            {@match.user.transactions_count}
            {ngettext(
              "bounty",
              "bounties",
              @match.user.transactions_count
            )}
          </span>
          across
          <span class="font-semibold font-display text-foreground/80">
            {ngettext(
              "%{count} project",
              "%{count} projects",
              @match.user.contributed_projects_count
            )}
          </span>
        </div>
        <div class="pt-4 flex flex-col gap-4">
          <%= for {project, total_earned} <- @match.projects |> Enum.take(2) do %>
            <.link
              navigate={User.url(project)}
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <.avatar class="h-10 w-10 rounded-lg saturate-0 bg-gradient-to-br brightness-75">
                <.avatar_image src={project.avatar_url} alt={project.name} />
                <.avatar_fallback class="rounded-lg">
                  {Algora.Util.initials(project.name)}
                </.avatar_fallback>
              </.avatar>
              <div class="flex flex-col">
                <div class="text-base font-medium text-foreground/80">
                  {project.name}
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <.icon name="tabler-star-filled" class="size-4 text-amber-400 mr-1" />{format_number(
                      project.stargazers_count
                    )}
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-foreground/80 font-display font-semibold">
                      {total_earned}
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp format_number(n) when n >= 1_000_000, do: "#{Float.round(n / 1_000_000, 1)}M"
  defp format_number(n) when n >= 1_000, do: "#{Float.round(n / 1_000, 1)}K"
  defp format_number(n), do: to_string(n)

  defp social_links do
    [
      {:website, "tabler-world"},
      {:github, "github"},
      {:twitter, "tabler-brand-x"},
      {:youtube, "tabler-brand-youtube"},
      {:twitch, "tabler-brand-twitch"},
      {:discord, "tabler-brand-discord"},
      {:slack, "tabler-brand-slack"},
      {:linkedin, "tabler-brand-linkedin"}
    ]
  end

  defp social_link(user, :github), do: if(login = user.provider_login, do: "https://github.com/#{login}")
  defp social_link(user, platform), do: Map.get(user, :"#{platform}_url")

  # Fetch contributions for all applicants and create a map for quick lookup
  defp fetch_applicants_contributions(applicants) do
    Enum.reduce(applicants, %{}, fn application, acc ->
      user = application.user
      contributions = Algora.Workspace.list_user_contributions(user.provider_login, limit: 5)
      Map.put(acc, user.id, contributions)
    end)
  end

  # Sort applicants by their total number of contributions
  defp sort_applicants_by_contributions(applicants, contributions_map) do
    Enum.sort_by(applicants, fn application -> length(Map.get(contributions_map, application.user.id, [])) end, :desc)
  end

  defp aggregate_contributions(contributions) do
    Enum.group_by(contributions, fn c -> c.repository.user end)
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
end
