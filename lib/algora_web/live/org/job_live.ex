defmodule AlgoraWeb.Org.JobLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Jobs
  alias Algora.Settings
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.ContractForm
  alias AlgoraWeb.Forms.TipForm

  require Logger

  defp assign_applicants(socket) do
    applicants = Jobs.list_job_applications(socket.assigns.job)
    contributions_map = fetch_applicants_contributions(applicants)
    sorted_applicants = sort_applicants_by_contributions(applicants, contributions_map)

    developers =
      socket.assigns.matches
      |> Enum.concat(applicants)
      |> Enum.map(& &1.user)

    socket
    |> assign(:developers, developers)
    |> assign(:applicants, sorted_applicants)
    |> assign(:contributions_map, contributions_map)
    |> assign(:total_applicants, length(applicants))
  end

  @impl true
  def mount(%{"org_handle" => handle, "id" => id}, _session, socket) do
    case Jobs.get_job_posting(id) do
      {:ok, job} ->
        matches = Settings.get_org_matches(job.user)
        imported_applicants = []
        # TODO: Replace with actual subscription check

        {:ok,
         socket
         |> assign(:page_title, job.title)
         |> assign(:job, job)
         |> assign(:matches, matches)
         |> assign(:total_matches, length(matches))
         |> assign(:imported_applicants, imported_applicants)
         |> assign(:total_imported, length(imported_applicants))
         |> assign(:show_import_drawer, false)
         |> assign(:show_share_drawer, false)
         |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
         |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
         |> assign(:contract_form, to_form(ContractForm.changeset(%ContractForm{}, %{})))
         |> assign(:share_drawer_type, nil)
         |> assign(:selected_developer, nil)
         |> assign(:import_form, to_form(%{"github_urls" => ""}, as: :import))
         |> assign(:github_urls, "")
         # Map of github_handle => %{status: :loading/:done, user: nil/User}
         |> assign(:importing_users, %{})
         |> assign_applicants()}

      _ ->
        {:ok, push_navigate(socket, to: ~p"/#{handle}/home")}
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

      <.section
        :if={@current_user_role in [:admin, :mod]}
        title="Applicants"
        subtitle="Developers who applied for this position"
      >
        <:actions>
          <.button variant="secondary" class="ml-auto" phx-click="toggle_import_drawer">
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
          <div class="grid grid-cols-1 gap-8 lg:grid-cols-3">
            <%= for {application, index} <- Enum.with_index(@applicants) do %>
              <div class={
                if @current_org.hiring_subscription == :inactive && index >= 3,
                  do: "filter blur-sm pointer-events-none"
              }>
                <.developer_card
                  application={application}
                  contributions={Map.get(@contributions_map, application.user.id, [])}
                  contract_type={
                    if(Enum.find(@matches, &(&1.user.id == application.user.id)),
                      do: "marketplace",
                      else: "bring_your_own"
                    )
                  }
                />
              </div>
            <% end %>
          </div>
        <% end %>
      </.section>

      <.section
        :if={@current_user_role in [:admin, :mod]}
        title="Matches"
        subtitle="Top developers matching your requirements"
      >
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
                if @current_org.hiring_subscription == :inactive && index != 0,
                  do: "filter blur-sm pointer-events-none"
              }>
                <.match_card match={match} />
              </div>
            <% end %>
          </div>
        <% end %>
      </.section>

      <.section :if={
        @current_user_role in [:admin, :mod] && @current_org.hiring_subscription != :active
      }>
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

    {share_drawer(assigns)}

    <.drawer show={@show_import_drawer} on_cancel={JS.push("toggle_import_drawer")} direction="right">
      <.drawer_header>
        <.drawer_title>Import Applicants</.drawer_title>
        <.drawer_description>
          Enter GitHub URLs or handles (comma or newline separated)
        </.drawer_description>
      </.drawer_header>

      <.drawer_content>
        <div class="space-y-4">
          <.simple_form for={@import_form} phx-submit="submit_import" class="space-y-4">
            <.input
              type="textarea"
              field={@import_form[:github_urls]}
              placeholder={import_placeholder()}
              phx-change="parse_github_urls"
              phx-debounce="300"
            />

            <%= if Enum.any?(@importing_users, fn {_, %{status: status}} -> status == :loading end) do %>
              <div class="flex items-center gap-2 text-sm text-muted-foreground">
                <.icon name="tabler-loader-2" class="h-4 w-4 animate-spin" />
                <span>
                  Loading users {Enum.count(@importing_users, fn {_, %{status: status}} ->
                    status == :done
                  end)}/{map_size(@importing_users)}
                </span>
              </div>
            <% else %>
              <%= if map_size(@importing_users) > 0 do %>
                <div class="flex items-center gap-2 text-sm text-muted-foreground">
                  <.icon name="tabler-check" class="h-4 w-4" />
                  <span>
                    Loaded users {Enum.count(@importing_users, fn {_, %{status: status}} ->
                      status == :done
                    end)}/{map_size(@importing_users)}
                  </span>
                </div>
              <% end %>
            <% end %>

            <div class="space-y-2">
              <%= for {handle, data} <- Enum.sort_by(@importing_users, fn {_, %{order: order}} -> order end) do %>
                <div class="flex items-center gap-2">
                  <%= if data.status == :loading do %>
                    <.avatar class="h-8 w-8">
                      <.avatar_image src="/images/placeholder-avatar.png" />
                      <.avatar_fallback>
                        {handle}
                      </.avatar_fallback>
                    </.avatar>
                    <span class="text-sm font-medium">{handle}</span>
                  <% else %>
                    <%= if data.user do %>
                      <.link
                        href={"https://github.com/#{data.user.provider_login}"}
                        target="_blank"
                        rel="noopener"
                        class="flex items-center gap-2"
                      >
                        <.avatar class="h-8 w-8">
                          <.avatar_image src={data.user.avatar_url} />
                          <.avatar_fallback>
                            {Algora.Util.initials(data.user.name)}
                          </.avatar_fallback>
                        </.avatar>
                        <span class="text-sm font-medium">{data.user.name}</span>
                        <span class="text-xs font-medium text-muted-foreground">
                          @{data.user.provider_login}
                        </span>
                      </.link>
                    <% else %>
                      <.avatar class="h-8 w-8">
                        <.avatar_fallback>?</.avatar_fallback>
                      </.avatar>
                      <span class="text-sm text-destructive">Failed to load @{handle}</span>
                    <% end %>
                  <% end %>
                </div>
              <% end %>
            </div>

            <:actions>
              <.button
                type="submit"
                disabled={
                  Enum.empty?(@importing_users) ||
                    Enum.any?(@importing_users, fn {_, %{status: status}} -> status == :loading end)
                }
              >
                Import
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </.drawer_content>
    </.drawer>
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

  @impl true
  def handle_event("toggle_import_drawer", _, socket) do
    {:noreply, assign(socket, :show_import_drawer, !socket.assigns.show_import_drawer)}
  end

  @impl true
  def handle_event("parse_github_urls", %{"import" => %{"github_urls" => urls}}, socket) do
    Algora.Admin.alert("Job applicant import initiated: #{inspect(urls)}", :info)
    # Parse GitHub URLs/handles from input and maintain order
    handles =
      urls
      |> String.split(~r/[\n,]/)
      |> Enum.map(&extract_github_handle/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.with_index()
      # Keep first occurrence if duplicate
      |> Enum.uniq_by(fn {handle, _} -> handle end)
      |> Map.new(fn {handle, index} -> {handle, %{status: :loading, user: nil, order: index}} end)

    # Start async user fetching for first handle only
    case Enum.min_by(handles, fn {_, %{order: order}} -> order end, &</2, fn -> nil end) do
      {handle, _} -> send(self(), {:fetch_github_user, handle})
      nil -> :ok
    end

    {:noreply,
     socket
     |> assign(:importing_users, handles)
     |> assign(:import_form, to_form(%{"github_urls" => urls}, as: :import))}
  end

  @impl true
  def handle_event("submit_import", _, socket) do
    # Create applications for all successfully imported users in original order
    results =
      socket.assigns.importing_users
      |> Enum.sort_by(fn {_handle, %{order: order}} -> order end)
      |> Enum.filter(fn {_handle, %{status: status, user: user}} ->
        status == :done && not is_nil(user)
      end)
      # TODO: batch this
      |> Enum.map(fn {_handle, %{user: user}} ->
        Jobs.ensure_application(socket.assigns.job.id, user, %{imported_at: DateTime.utc_now()})
      end)

    if Enum.all?(results, &match?({:ok, _}, &1)) do
      {:noreply,
       socket
       |> put_flash(:info, "Successfully imported applicants")
       |> assign(:show_import_drawer, false)
       |> assign(:importing_users, %{})
       |> assign_applicants()}
    else
      {:noreply, put_flash(socket, :error, "Failed to import some applicants")}
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

  @impl true
  def handle_info({:fetch_github_user, handle}, socket) do
    # TODO: handle expired token
    case Accounts.get_access_token(socket.assigns.current_user) do
      {:ok, token} ->
        case Algora.Workspace.ensure_user(token, handle) do
          {:ok, user} ->
            importing_users =
              update_in(
                socket.assigns.importing_users,
                [handle],
                &%{&1 | status: :done, user: user}
              )

            # Find next handle to process based on order
            next_handle =
              importing_users
              |> Enum.filter(fn {_, %{status: status}} -> status == :loading end)
              |> Enum.min_by(fn {_, %{order: order}} -> order end, &</2, fn -> nil end)
              |> case do
                {handle, _} -> handle
                nil -> nil
              end

            # Start fetching next handle if exists
            if next_handle, do: send(self(), {:fetch_github_user, next_handle})

            {:noreply, assign(socket, :importing_users, importing_users)}

          {:error, _reason} ->
            importing_users =
              update_in(
                socket.assigns.importing_users,
                [handle],
                &%{&1 | status: :done, user: nil}
              )

            # Find next handle to process based on order
            next_handle =
              importing_users
              |> Enum.filter(fn {_, %{status: status}} -> status == :loading end)
              |> Enum.min_by(fn {_, %{order: order}} -> order end, &>/2, fn -> nil end)
              |> case do
                {handle, _} -> handle
                nil -> nil
              end

            # Start fetching next handle if exists
            if next_handle, do: send(self(), {:fetch_github_user, next_handle})

            {:noreply, assign(socket, :importing_users, importing_users)}
        end

      {:error, reason} ->
        Logger.error("Failed to import job applicants: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
    end
  end

  defp extract_github_handle(url) do
    cond do
      # Handle github.com URLs
      String.contains?(url, "github.com/") ->
        url
        |> String.split("github.com/")
        |> List.last()
        |> String.split("/")
        |> List.first()
        |> String.trim()

      # Handle raw handles
      String.match?(url, ~r/^@?[a-zA-Z0-9-]+$/) ->
        url
        |> String.trim_leading("@")
        |> String.trim()

      true ->
        nil
    end
  end

  defp developer_card(assigns) do
    ~H"""
    <div class="h-full relative border bg-card rounded-xl text-card-foreground shadow p-6">
      <div class="w-full truncate">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div class="flex items-center gap-4">
            <.link navigate={User.url(@application.user)}>
              <.avatar class="h-12 w-12 rounded-full">
                <.avatar_image src={@application.user.avatar_url} alt={@application.user.name} />
                <.avatar_fallback class="rounded-lg">
                  {Algora.Util.initials(@application.user.name)}
                </.avatar_fallback>
              </.avatar>
            </.link>

            <div>
              <div class="flex items-center gap-1 text-base text-foreground">
                <.link navigate={User.url(@application.user)} class="font-semibold hover:underline">
                  {@application.user.name} {Algora.Misc.CountryEmojis.get(@application.user.country)}
                </.link>
              </div>
              <div
                :if={@application.user.provider_meta}
                class="pt-0.5 flex items-center gap-x-2 gap-y-1 text-xs text-muted-foreground max-w-[250px] 2xl:max-w-none truncate"
              >
                <.link
                  :if={@application.user.provider_login}
                  href={"https://github.com/#{@application.user.provider_login}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <.icon name="github" class="shrink-0 h-4 w-4" />
                  <span class="line-clamp-1">{@application.user.provider_login}</span>
                </.link>
                <.link
                  :if={@application.user.provider_meta["twitter_handle"]}
                  href={"https://x.com/#{@application.user.provider_meta["twitter_handle"]}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <.icon name="tabler-brand-x" class="shrink-0 h-4 w-4" />
                  <span class="line-clamp-1">
                    {@application.user.provider_meta["twitter_handle"]}
                  </span>
                </.link>
                <div class="flex items-center gap-1">
                  <.icon name="tabler-calendar" class="shrink-0 h-4 w-4" />
                  <span class="line-clamp-1 text-xs">
                    <%= if @application.imported_at do %>
                      Imported
                    <% else %>
                      Applied
                    <% end %>
                    on {Calendar.strftime(
                      @application.imported_at || @application.inserted_at,
                      "%B %d"
                    )}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="pt-2 flex items-center justify-center gap-2">
          <.button
            phx-click="share_opportunity"
            phx-value-user_id={@application.user.id}
            phx-value-type="bounty"
            variant="outline"
            size="sm"
          >
            Bounty
          </.button>
          <.button
            phx-click="share_opportunity"
            phx-value-user_id={@application.user.id}
            phx-value-type="tip"
            variant="outline"
            size="sm"
          >
            Interview
          </.button>
          <.button
            phx-click="share_opportunity"
            phx-value-user_id={@application.user.id}
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
                href={"https://github.com/#{owner.provider_login}/#{List.first(contributions).repository.name}/pulls?q=author%3A#{@application.user.provider_login}+is%3Amerged+"}
                target="_blank"
                rel="noopener"
                class="flex items-center gap-3 group rounded-xl pr-2 bg-card/50 border border-border/50 hover:border-border transition-all"
              >
                <img
                  src={owner.avatar_url}
                  class="h-12 w-12 rounded-xl rounded-r-none group-hover:saturate-100 transition-all"
                  alt={owner.name}
                />
                <div class="w-full flex flex-col text-xs font-medium gap-0.5">
                  <span class="flex items-start justify-between gap-5">
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
    contributions
    |> Enum.group_by(fn c -> c.repository.user end)
    |> Enum.sort_by(
      fn {owner, repos} ->
        max(
          owner.stargazers_count,
          repos
          |> Enum.map(& &1.repository.stargazers_count)
          |> Enum.sum()
        )
      end,
      :desc
    )
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

  defp import_placeholder do
    """
    https://github.com/user1
    https://github.com/user2
    https://github.com/user3
    """
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
              {Algora.Misc.CountryEmojis.get(@selected_developer.country)}
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
end
