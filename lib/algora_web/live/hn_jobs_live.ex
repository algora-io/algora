defmodule AlgoraWeb.HNJobsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Jobs
  alias Algora.Jobs.JobPosting
  alias Algora.Repo
  alias Algora.Settings
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.ContractForm
  alias AlgoraWeb.Forms.TipForm

  require Logger

  defp default_tab, do: "jobs"

  @impl true
  def mount(_params, _session, socket) do
    jobs =
      JobPosting
      # |> where([j], j.id in ^Settings.get_hn_job_ids())
      |> order_by([j], desc: j.inserted_at)
      |> Repo.all()
      |> Repo.preload(:user)

    jobs_by_user = Enum.group_by(jobs, & &1.user)

    {:ok,
     socket
     |> assign(:page_title, "HN Who's Hiring")
     |> assign(:show_share_drawer, false)
     |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
     |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
     |> assign(:contract_form, to_form(ContractForm.changeset(%ContractForm{}, %{})))
     |> assign(:share_drawer_type, nil)
     |> assign(:selected_developer, nil)
     |> assign(:jobs, jobs)
     |> assign(:jobs_by_user, jobs_by_user)
     |> assign_developers()
     |> assign_user_applications()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :current_tab, params["tab"] || default_tab())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-8 p-4 sm:p-6 lg:p-8">
      <.section>
        <.card class="flex flex-col p-6">
          <div class="flex flex-col md:flex-row md:justify-between">
            <div>
              <div class="flex items-start md:items-center gap-3">
                <.avatar class="h-16 w-16">
                  <.avatar_image src="https://news.ycombinator.com/y18.svg" />
                </.avatar>
                <div>
                  <div class="text-lg text-foreground font-bold font-display">
                    HN Who's Hiring
                  </div>
                  <div class="text-sm text-muted-foreground line-clamp-2 md:line-clamp-1">
                    Browse and search the HN Who's Hiring Database
                  </div>
                </div>
              </div>
            </div>
          </div>
        </.card>
      </.section>

      <div>
        <div class="flex flex-col md:flex-row md:items-center gap-4 mb-8">
          <%= for {tab, label, count} <- [
            {"jobs", "Jobs", length(@jobs)},
            {"developers", "Developers", length(@job_seekers)},
            {"matches", "Matches", length(@matches)}
          ] do %>
            <label class={[
              "group relative flex cursor-pointer rounded-lg px-4 py-2 shadow-sm focus:outline-none",
              "border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10",
              "border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10"
            ]}>
              <input
                type="radio"
                name="tab"
                value={tab}
                checked={@current_tab == tab}
                class="sr-only"
                phx-click="change_tab"
                phx-value-tab={tab}
              />
              <span class="flex items-center justify-between w-full gap-2">
                <span class="text-sm font-medium">{label}</span>
                <span class="text-xs text-muted-foreground">
                  {count}
                </span>
              </span>
            </label>
          <% end %>
        </div>
        <%= case @current_tab do %>
          <% "jobs" -> %>
            <.section title="Jobs" subtitle="All job postings">
              <:actions>
                <.button variant="default" phx-click="toggle_import_drawer">
                  Post your job
                </.button>
              </:actions>
              <%= if Enum.empty?(@jobs_by_user) do %>
                <.card class="rounded-lg bg-card py-12 text-center lg:rounded-[2rem]">
                  <.card_header>
                    <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                      <.icon name="tabler-briefcase" class="h-8 w-8 text-muted-foreground" />
                    </div>
                    <.card_title>No jobs yet</.card_title>
                    <.card_description>
                      Open positions will appear here once created
                    </.card_description>
                  </.card_header>
                </.card>
              <% else %>
                <div class="grid gap-12">
                  <%= for {user, jobs} <- @jobs_by_user do %>
                    <.card class="flex flex-col p-6">
                      <div class="flex items-start md:items-center gap-4">
                        <.avatar class="h-16 w-16">
                          <.avatar_image src={user.avatar_url} />
                          <.avatar_fallback>
                            {Algora.Util.initials(user.name)}
                          </.avatar_fallback>
                        </.avatar>
                        <div>
                          <div class="text-lg text-foreground font-bold font-display">
                            {user.name}
                          </div>
                          <div class="text-sm text-muted-foreground line-clamp-2 md:line-clamp-1">
                            {user.bio}
                          </div>
                          <div class="flex gap-2 items-center">
                            <%= for {platform, icon} <- social_icons(),
                      url = social_link(user, platform),
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

                      <div class="pt-8 grid gap-8">
                        <%= for job <- jobs do %>
                          <div class="flex flex-col md:flex-row justify-between gap-4">
                            <div>
                              <div>
                                <div class="text-lg font-semibold">
                                  {job.title}
                                </div>
                              </div>
                              <div :if={job.description} class="pt-1 text-sm text-muted-foreground">
                                {job.description}
                              </div>
                              <div class="pt-2 flex flex-wrap gap-2">
                                <%= for tech <- job.tech_stack do %>
                                  <.badge variant="outline">{tech}</.badge>
                                <% end %>
                              </div>
                            </div>
                            <%= if MapSet.member?(@user_applications, job.id) do %>
                              <.button disabled class="opacity-50">
                                <.icon name="tabler-check" class="h-4 w-4 mr-2 -ml-1" /> Applied
                              </.button>
                            <% else %>
                              <.button phx-click="apply_job" phx-value-job-id={job.id}>
                                <.icon name="github" class="h-4 w-4 mr-2" /> Apply with GitHub
                              </.button>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                    </.card>
                  <% end %>
                </div>
              <% end %>
            </.section>
          <% "developers" -> %>
            <.section title="Developers" subtitle="All job seekers">
              <:actions>
                <.button variant="default" phx-click="toggle_import_drawer">
                  Sign up
                </.button>
              </:actions>
              <%= if Enum.empty?(@job_seekers) do %>
                <.card class="rounded-lg bg-card py-12 text-center lg:rounded-[2rem]">
                  <.card_header>
                    <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                      <.icon name="tabler-users" class="h-8 w-8 text-muted-foreground" />
                    </div>
                    <.card_title>No job seekers yet</.card_title>
                    <.card_description>
                      Job seekers will appear here once created
                    </.card_description>
                  </.card_header>
                </.card>
              <% else %>
                <div class="grid grid-cols-1 gap-8 lg:grid-cols-3">
                  <%= for job_seeker <- @job_seekers do %>
                    <div>
                      <.developer_card
                        user={job_seeker}
                        contributions={Map.get(@contributions_map, job_seeker.id, [])}
                        contract_type="bring_your_own"
                      />
                    </div>
                  <% end %>
                </div>
              <% end %>
            </.section>
          <% "matches" -> %>
            <.section title="Matches" subtitle="Top developers matching your requirements">
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
                  <%= for match <- @matches |> Enum.take(if @current_org.hiring_subscription == :active, do: length(@matches), else: 3) do %>
                    <div>
                      <.match_card
                        user={match.user}
                        tech_stack={[]}
                        contributions={Map.get(@contributions_map, match.user.id, [])}
                        contract_type="bring_your_own"
                      />
                    </div>
                  <% end %>
                  <%= if @current_org.hiring_subscription != :active do %>
                    <div class="relative lg:col-span-3">
                      <img
                        src={~p"/images/screenshots/job-matches-more.png"}
                        class="w-full aspect-[1368/398]"
                      />
                      <div class="absolute inset-0 flex items-center font-bold text-foreground justify-center text-3xl md:text-4xl">
                        + {length(@matches) - 3} more matches
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </.section>
        <% end %>
      </div>
    </div>

    {share_drawer(assigns)}
    """
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: "/hn/#{tab}")}
  end

  @impl true
  def handle_event("apply_job", %{"job-id" => job_id}, socket) do
    if socket.assigns[:current_user] do
      if Accounts.has_fresh_token?(socket.assigns.current_user) do
        case Jobs.create_application(job_id, socket.assigns.current_user) do
          {:ok, _application} ->
            {:noreply, assign_user_applications(socket)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to submit application. Please try again.")}
        end
      else
        {:noreply, redirect(socket, external: Algora.Github.authorize_url(%{return_to: "/hn/jobs"}))}
      end
    else
      {:noreply, redirect(socket, external: Algora.Github.authorize_url(%{return_to: "/hn/jobs"}))}
    end
  end

  @impl true
  def handle_event(
        "share_opportunity",
        %{"user_id" => user_id, "type" => "contract", "contract_type" => contract_type},
        socket
      ) do
    developer = Enum.find(socket.assigns.developers, &(&1.id == user_id))
    match = Enum.find(socket.assigns.matches, &(&1.user.id == user_id))
    hourly_rate = match[:hourly_rate]

    hours_per_week = developer.hours_per_week || 30

    {:noreply,
     socket
     |> assign(:main_contract_form_open?, true)
     |> assign(
       :main_contract_form,
       %ContractForm{
         contract_type: String.to_existing_atom(contract_type),
         contractor: match[:user] || developer
       }
       |> ContractForm.changeset(%{
         amount: if(hourly_rate, do: Money.mult!(hourly_rate, hours_per_week)),
         hourly_rate: hourly_rate,
         contractor_handle: developer.provider_login,
         hours_per_week: hours_per_week,
         title: "#{socket.assigns.current_org.name} OSS Development",
         description: "Open source contribution to #{socket.assigns.current_org.name} for a week"
       })
       |> to_form()
     )}
  end

  @impl true
  def handle_event("share_opportunity", %{"user_id" => user_id, "type" => type}, socket) do
    developer = Enum.find(socket.assigns.developers, &(&1.id == user_id))

    {:noreply,
     socket
     |> assign(:selected_developer, developer)
     |> assign(:share_drawer_type, type)
     |> assign(:show_share_drawer, true)}
  end

  @impl true
  def handle_event("close_share_drawer", _params, socket) do
    {:noreply, assign(socket, :show_share_drawer, false)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp assign_developers(socket) do
    job_seekers = Repo.all(from u in User, where: u.provider_login in ^Settings.get_hn_job_seekers())
    matches = []

    developers = Enum.concat(matches, job_seekers)

    contributions_map = fetch_applicants_contributions(developers, [])

    socket
    |> assign(:developers, developers)
    |> assign(:job_seekers, sort_by_contributions(job_seekers, contributions_map))
    |> assign(:matches, sort_by_contributions(matches, contributions_map))
    |> assign(:contributions_map, contributions_map)
  end

  defp assign_user_applications(socket) do
    user_applications =
      if socket.assigns[:current_user] do
        Jobs.list_user_applications(socket.assigns.current_user)
      else
        MapSet.new()
      end

    assign(socket, :user_applications, user_applications)
  end

  defp developer_card(assigns) do
    ~H"""
    <div class="h-full relative border ring-1 ring-transparent hover:ring-border transition-all bg-card group rounded-xl text-card-foreground shadow p-6">
      <div class="w-full truncate">
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
                  {@user.name}
                  <span :if={@user.country}>
                    {Algora.Misc.CountryEmojis.get(@user.country)}
                  </span>
                </.link>
              </div>
              <div
                :if={@user.provider_meta}
                class="pt-0.5 flex items-center gap-x-2 gap-y-1 text-xs text-muted-foreground max-w-[250px] 2xl:max-w-none truncate"
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
                  <span class="line-clamp-1">
                    {@user.provider_meta["twitter_handle"]}
                  </span>
                </.link>
              </div>
            </div>
          </div>
        </div>

        <div class="pt-2 flex items-center justify-center gap-2">
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
            phx-value-contract_type={@contract_type}
            variant="outline"
            size="sm"
          >
            Contract
          </.button>
        </div>

        <div :if={@contributions != []} class="mt-4">
          <p class="text-xs text-muted-foreground uppercase font-semibold">
            Top contributions
          </p>
          <div class="flex flex-col gap-3 mt-2">
            <%= if @contributions == [] do %>
              <%= for _ <- 1..3 do %>
                <div class="h-[50px] animate-pulse rounded-xl bg-muted/50 border border-border/50" />
              <% end %>
            <% else %>
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
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp match_card(assigns) do
    ~H"""
    <div class="h-full relative border ring-1 ring-transparent hover:ring-border transition-all bg-card group rounded-xl text-card-foreground shadow p-6">
      <div class="w-full truncate">
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
                  {@user.name}
                  <span :if={@user.country}>
                    {Algora.Misc.CountryEmojis.get(@user.country)}
                  </span>
                </.link>
              </div>
              <div
                :if={@user.provider_meta}
                class="pt-0.5 flex items-center gap-x-2 gap-y-1 text-xs text-muted-foreground max-w-[250px] 2xl:max-w-none truncate"
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
                  <span class="line-clamp-1">
                    {@user.provider_meta["twitter_handle"]}
                  </span>
                </.link>
              </div>
            </div>
          </div>
        </div>

        <div class="pt-2 flex items-center justify-center gap-2">
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
            phx-value-contract_type={@contract_type}
            variant="outline"
            size="sm"
          >
            Contract
          </.button>
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
      </div>
    </div>
    """
  end

  # Fetch contributions for all applicants and create a map for quick lookup
  defp fetch_applicants_contributions(users, tech_stack) do
    users
    |> Enum.map(& &1.id)
    |> Algora.Workspace.list_user_contributions(tech_stack: tech_stack)
    |> Enum.group_by(& &1.user.id)
  end

  defp sort_by_contributions(applicants, contributions_map) do
    Enum.sort_by(applicants, &Algora.Cloud.get_contribution_score([], &1, contributions_map), :desc)
  end

  defp aggregate_contributions(contributions) do
    groups = Enum.group_by(contributions, fn c -> c.repository.user end)

    contributions
    |> Enum.map(fn c -> {c.repository.user, groups[c.repository.user]} end)
    |> Enum.uniq_by(fn {owner, _} -> owner.id end)
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

  defp share_drawer_header(%{share_drawer_type: "contract"} = assigns) do
    ~H"""
    <.drawer_header>
      <.drawer_title>Offer Contract</.drawer_title>
      <.drawer_description>
        {@selected_developer.name} will be notified and can accept or decline. You can auto-renew or cancel the contract at the end of each period.
      </.drawer_description>
    </.drawer_header>
    """
  end

  defp share_drawer_header(%{share_drawer_type: "bounty"} = assigns) do
    ~H"""
    <.drawer_header>
      <.drawer_title>Share Bounty</.drawer_title>
      <.drawer_description>
        Share a bounty opportunity with {@selected_developer.name}. They will be notified and can choose to work on it.
      </.drawer_description>
    </.drawer_header>
    """
  end

  defp share_drawer_header(%{share_drawer_type: "tip"} = assigns) do
    ~H"""
    <.drawer_header>
      <.drawer_title>Send Tip</.drawer_title>
      <.drawer_description>
        Send a tip to {@selected_developer.name} to show appreciation for their contributions.
      </.drawer_description>
    </.drawer_header>
    """
  end

  defp share_drawer_content(%{share_drawer_type: "contract"} = assigns) do
    ~H"""
    <.form for={@contract_form} phx-submit="create_contract">
      <.card>
        <.card_header>
          <.card_title>Contract Details</.card_title>
        </.card_header>
        <.card_content class="pt-0 flex flex-col">
          <div class="space-y-4">
            <.input
              label="Hourly Rate"
              icon="tabler-currency-dollar"
              field={@contract_form[:hourly_rate]}
            />
            <.input label="Hours per Week" field={@contract_form[:hours_per_week]} />
          </div>
          <div class="pt-8 ml-auto flex gap-4">
            <.button variant="secondary" phx-click="close_share_drawer" type="button">
              Cancel
            </.button>
            <.button type="submit">
              Send Contract Offer <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
            </.button>
          </div>
        </.card_content>
      </.card>
    </.form>
    """
  end

  defp share_drawer_content(%{share_drawer_type: "bounty"} = assigns) do
    ~H"""
    <.form for={@bounty_form} phx-submit="create_bounty">
      <.card>
        <.card_header>
          <.card_title>Bounty Details</.card_title>
        </.card_header>
        <.card_content class="pt-0 flex flex-col">
          <div class="space-y-4">
            <.input type="hidden" name="bounty_form[visibility]" value="exclusive" />
            <.input
              type="hidden"
              name="bounty_form[shared_with][]"
              value={
                case @selected_developer do
                  %{handle: nil, provider_id: provider_id} -> [to_string(provider_id)]
                  %{id: id} -> [id]
                end
              }
            />
            <.input
              label="URL"
              field={@bounty_form[:url]}
              placeholder="https://github.com/owner/repo/issues/123"
            />
            <.input label="Amount" icon="tabler-currency-dollar" field={@bounty_form[:amount]} />
          </div>
          <div class="pt-8 ml-auto flex gap-4">
            <.button variant="secondary" phx-click="close_share_drawer" type="button">
              Cancel
            </.button>
            <.button type="submit">
              Share Bounty <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
            </.button>
          </div>
        </.card_content>
      </.card>
    </.form>
    """
  end

  defp share_drawer_content(%{share_drawer_type: "tip"} = assigns) do
    ~H"""
    <.form for={@tip_form} phx-submit="create_tip">
      <.card>
        <.card_header>
          <.card_title>Tip Details</.card_title>
        </.card_header>
        <.card_content class="pt-0 flex flex-col">
          <div class="space-y-4">
            <input
              type="hidden"
              name="tip_form[github_handle]"
              value={@selected_developer.provider_login}
            />
            <.input label="Amount" icon="tabler-currency-dollar" field={@tip_form[:amount]} />
            <.input
              label="URL"
              field={@tip_form[:url]}
              placeholder="https://github.com/owner/repo/issues/123"
              helptext="We'll add a comment to the issue to notify the developer."
            />
          </div>
          <div class="pt-8 ml-auto flex gap-4">
            <.button variant="secondary" phx-click="close_share_drawer" type="button">
              Cancel
            </.button>
            <.button type="submit">
              Send Tip <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
            </.button>
          </div>
        </.card_content>
      </.card>
    </.form>
    """
  end

  defp share_drawer_developer_info(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <.card_title>Developer</.card_title>
      </.card_header>
      <.card_content class="pt-0">
        <div class="flex items-start gap-4">
          <.avatar class="h-20 w-20 rounded-full">
            <.avatar_image src={@selected_developer.avatar_url} alt={@selected_developer.name} />
            <.avatar_fallback class="rounded-lg">
              {Algora.Util.initials(@selected_developer.name)}
            </.avatar_fallback>
          </.avatar>

          <div>
            <div class="flex items-center gap-1 text-base text-foreground">
              <span class="font-semibold">{@selected_developer.name}</span>
              <span :if={@selected_developer.country}>
                {Algora.Misc.CountryEmojis.get(@selected_developer.country)}
              </span>
            </div>

            <div
              :if={@selected_developer.provider_meta}
              class="pt-0.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm"
            >
              <.link
                :if={@selected_developer.provider_login}
                href={"https://github.com/#{@selected_developer.provider_login}"}
                target="_blank"
                class="flex items-center gap-1 hover:underline"
              >
                <.icon name="github" class="h-4 w-4" />
                <span class="whitespace-nowrap">{@selected_developer.provider_login}</span>
              </.link>
              <.link
                :if={@selected_developer.provider_meta["twitter_handle"]}
                href={"https://x.com/#{@selected_developer.provider_meta["twitter_handle"]}"}
                target="_blank"
                class="flex items-center gap-1 hover:underline"
              >
                <.icon name="tabler-brand-x" class="h-4 w-4" />
                <span class="whitespace-nowrap">
                  {@selected_developer.provider_meta["twitter_handle"]}
                </span>
              </.link>
              <div :if={@selected_developer.provider_meta["location"]} class="flex items-center gap-1">
                <.icon name="tabler-map-pin" class="h-4 w-4" />
                <span class="whitespace-nowrap">
                  {@selected_developer.provider_meta["location"]}
                </span>
              </div>
              <div :if={@selected_developer.provider_meta["company"]} class="flex items-center gap-1">
                <.icon name="tabler-building" class="h-4 w-4" />
                <span class="whitespace-nowrap">
                  {@selected_developer.provider_meta["company"] |> String.trim_leading("@")}
                </span>
              </div>
            </div>

            <div class="pt-1.5 flex flex-wrap gap-2">
              <%= for tech <- @selected_developer.tech_stack do %>
                <div class="rounded-lg bg-foreground/5 px-2 py-1 text-xs font-medium text-foreground ring-1 ring-inset ring-foreground/25">
                  {tech}
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </.card_content>
    </.card>
    """
  end

  defp share_drawer(assigns) do
    ~H"""
    <.drawer show={@show_share_drawer} direction="bottom" on_cancel="close_share_drawer">
      <.share_drawer_header
        :if={@selected_developer}
        selected_developer={@selected_developer}
        share_drawer_type={@share_drawer_type}
      />
      <.drawer_content :if={@selected_developer} class="mt-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <.share_drawer_developer_info selected_developer={@selected_developer} />
          <.share_drawer_content
            :if={@selected_developer}
            selected_developer={@selected_developer}
            share_drawer_type={@share_drawer_type}
            bounty_form={@bounty_form}
            tip_form={@tip_form}
            contract_form={@contract_form}
          />
        </div>
      </.drawer_content>
    </.drawer>
    """
  end

  defp social_icons do
    %{
      website: "tabler-world",
      github: "github",
      twitter: "tabler-brand-x",
      youtube: "tabler-brand-youtube",
      twitch: "tabler-brand-twitch",
      discord: "tabler-brand-discord",
      slack: "tabler-brand-slack",
      linkedin: "tabler-brand-linkedin"
    }
  end

  defp social_link(user, :github), do: if(login = user.provider_login, do: "https://github.com/#{login}")
  defp social_link(user, platform), do: Map.get(user, :"#{platform}_url")
end
