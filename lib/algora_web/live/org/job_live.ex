defmodule AlgoraWeb.Org.JobLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts.User
  alias Algora.Jobs
  alias Algora.Settings
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.ContractForm
  alias AlgoraWeb.Forms.TipForm

  require Logger

  defp subscribe(job) do
    Phoenix.PubSub.subscribe(Algora.PubSub, "job:#{job.id}")
  end

  defp broadcast(job, event) do
    Phoenix.PubSub.broadcast(Algora.PubSub, "job:#{job.id}", event)
  end

  @impl true
  def mount(%{"org_handle" => handle, "id" => id, "tab" => tab}, _session, socket) do
    case Jobs.get_job_posting(id) do
      {:ok, job} ->
        if connected?(socket), do: subscribe(job)

        {:ok,
         socket
         |> assign(:share_url, url(~p"/#{handle}/jobs/"))
         |> assign(:page_title, job.title)
         |> assign(:job, job)
         |> assign(:show_import_drawer, false)
         |> assign(:show_share_drawer, false)
         |> assign(:current_tab, tab)
         |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
         |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
         |> assign(:contract_form, to_form(ContractForm.changeset(%ContractForm{}, %{})))
         |> assign(:share_drawer_type, nil)
         |> assign(:selected_developer, nil)
         |> assign(:import_form, to_form(%{"github_urls" => ""}, as: :import))
         |> assign(:github_urls, "")
         # Map of github_handle => %{status: :loading/:done, user: nil/User}
         |> assign(:importing_users, %{})
         |> assign(:loading_contribution_handle, nil)
         |> assign_applicants()}

      _ ->
        {:ok, push_navigate(socket, to: ~p"/#{handle}/home")}
    end
  end

  @impl true
  def mount(%{"org_handle" => handle, "id" => id}, _session, socket) do
    {:ok, push_navigate(socket, to: ~p"/#{handle}/jobs/#{id}/applicants")}
  end

  @impl true
  def handle_params(%{"tab" => "activate", "org_handle" => handle, "id" => id}, _uri, socket) do
    Algora.Admin.alert("Activation request received for #{AlgoraWeb.Endpoint.url()}/#{handle}/jobs/#{id}", :info)
    {:noreply, redirect(socket, external: AlgoraWeb.Constants.get(:calendar_url))}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _uri, socket) do
    {:noreply, assign(socket, :current_tab, tab)}
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
                <div class="text-lg font-semibold">
                  {@job.title}
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
            </div>
            <div class="hidden md:flex flex-col items-center">
              <h3 class="text-lg font-semibold">
                Share on socials
              </h3>
              <div class="mt-2 flex gap-3">
                <.social_share_button id="twitter-share-url" icon="tabler-brand-x" value={@share_url} />
                <.social_share_button
                  id="reddit-share-url"
                  icon="tabler-brand-reddit"
                  value={@share_url}
                />
                <.social_share_button
                  id="linkedin-share-url"
                  icon="tabler-brand-linkedin"
                  value={@share_url}
                />
                <.social_share_button
                  id="hackernews-share-url"
                  icon="tabler-brand-ycombinator"
                  value={@share_url}
                />
              </div>
              <div class="mt-4 relative aspect-[1200/630] max-w-[12rem] w-full rounded-lg ring-1 ring-border bg-black overflow-hidden">
                <img
                  src={~p"/og/#{@current_org.handle}/jobs"}
                  alt={@job.title}
                  class="object-cover"
                  loading="lazy"
                />
              </div>
            </div>
          </div>
        </.card>
      </.section>

      <div>
        <div class="flex flex-col md:flex-row md:items-center gap-4 mb-8">
          <%= for {tab, label, count} <- [
            {"applicants", "Applicants", length(@applicants)},
            {"imports", "Imports", length(@imports)},
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
          <% "applicants" -> %>
            <.section title="Applicants" subtitle="Developers who applied for this position">
              <:actions>
                <.button variant="secondary" phx-click="toggle_import_drawer">
                  Import
                </.button>
                <.button variant="default" phx-click="screen_applicants">
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
                      Share your job posting with your network
                    </.card_description>
                  </.card_header>
                </.card>
              <% else %>
                <div class="grid grid-cols-1 gap-8 lg:grid-cols-3">
                  <%= for application <- @applicants do %>
                    <div>
                      <.developer_card
                        tech_stack={@job.tech_stack |> Enum.take(1)}
                        application={application}
                        contributions={Map.get(@contributions_map, application.user.id, [])}
                        contract_type="bring_your_own"
                        loading_contribution_handle={@loading_contribution_handle}
                      />
                    </div>
                  <% end %>
                </div>
              <% end %>
            </.section>
          <% "imports" -> %>
            <.section title="Imports" subtitle="Import applicants from external sources">
              <:actions>
                <.button variant="default" phx-click="toggle_import_drawer">
                  Import
                </.button>
              </:actions>
              <%= if Enum.empty?(@imports) do %>
                <.card class="rounded-lg bg-card py-12 text-center lg:rounded-[2rem]">
                  <.card_header>
                    <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                      <.icon name="tabler-users" class="h-8 w-8 text-muted-foreground" />
                    </div>
                    <.card_title>No imports yet</.card_title>
                    <.card_description>
                      Import applicants from external sources
                    </.card_description>
                  </.card_header>
                </.card>
              <% else %>
                <div class="grid grid-cols-1 gap-8 lg:grid-cols-3">
                  <%= for application <- @imports do %>
                    <div>
                      <.developer_card
                        tech_stack={@job.tech_stack |> Enum.take(1)}
                        application={application}
                        contributions={Map.get(@contributions_map, application.user.id, [])}
                        contract_type="bring_your_own"
                        loading_contribution_handle={@loading_contribution_handle}
                      />
                    </div>
                  <% end %>
                </div>
              <% end %>
            </.section>
          <% "matches" -> %>
            <.section title="Matches" subtitle="Top developers matching your requirements">
              <:actions>
                <.button variant="default" phx-click="screen_applicants">
                  Screen
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
                  <%= for match <- @matches |> Enum.take(if @current_org.hiring_subscription == :active, do: length(@matches), else: 3) do %>
                    <div>
                      <.match_card
                        user={match.user}
                        tech_stack={@job.tech_stack |> Enum.take(1)}
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

      <.section :if={@current_org.hiring_subscription != :active}>
        <div class="border ring-1 ring-transparent rounded-xl overflow-hidden">
          <div class="bg-card/75 flex flex-col h-full p-4 rounded-xl border-t-4 sm:border-t-0 sm:border-l-4 border-emerald-400">
            <div class="grid md:grid-cols-2 gap-8 p-4 sm:p-6">
              <div>
                <h3 class="text-3xl font-semibold text-foreground">
                  <span class="text-success-300 drop-shadow-[0_1px_5px_#34d39980]">Activate</span>
                  Annual Subscription
                </h3>
                <ul class="mt-4 text-base grid grid-cols-1 gap-3">
                  <li class="flex items-center gap-4 md:gap-3">
                    <div class="shrink-0 flex items-center justify-center rounded-full bg-success-300/10 size-12 md:size-10 border border-success-300/20">
                      <.icon name="tabler-speakerphone" class="size-8 md:size-6 text-success-300" />
                    </div>
                    <span>
                      <span class="font-semibold text-success-300">Reach 50K+ devs</span>
                      <br class="md:hidden" /> with unlimited job postings
                    </span>
                  </li>
                  <li class="flex items-center gap-4 md:gap-3">
                    <div class="shrink-0 flex items-center justify-center rounded-full bg-success-300/10 size-12 md:size-10 border border-success-300/20">
                      <.icon name="tabler-lock-open" class="size-8 md:size-6 text-success-300" />
                    </div>
                    <span>
                      <span class="font-semibold text-success-300">Access top 1% users</span>
                      <br class="md:hidden" /> matching your preferences
                    </span>
                  </li>
                  <li class="flex items-center gap-4 md:gap-3">
                    <div class="shrink-0 flex items-center justify-center rounded-full bg-success-300/10 size-12 md:size-10 border border-success-300/20">
                      <.icon name="tabler-wand" class="size-8 md:size-6 text-success-300" />
                    </div>
                    <span>
                      <span class="font-semibold text-success-300">Auto-rank applicants</span>
                      <br class="md:hidden" /> for OSS contribution history
                    </span>
                  </li>
                  <li class="flex items-center gap-4 md:gap-3">
                    <div class="shrink-0 flex items-center justify-center rounded-full bg-success-300/10 size-12 md:size-10 border border-success-300/20">
                      <.icon name="tabler-currency-dollar" class="size-8 md:size-6 text-success-300" />
                    </div>
                    <span>
                      <span class="font-semibold text-success-300">Trial top candidates</span>
                      <br class="md:hidden" /> using contracts and bounties
                    </span>
                  </li>
                </ul>
              </div>
              <div class="flex flex-col justify-center items-center text-center">
                <.button
                  patch={~p"/#{@current_org.handle}/jobs/#{@job.id}/activate"}
                  variant="none"
                  class="group bg-emerald-900/10 text-emerald-300 transition-colors duration-75 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border border-emerald-400/40 hover:border-emerald-400/50 focus:border-emerald-400/50 h-[8rem]"
                  size="xl"
                >
                  <div class="flex flex-col items-center gap-1 font-semibold">
                    <span>Activate subscription</span>
                  </div>
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

            <div class="flex justify-between items-center">
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

              <.button
                type="submit"
                class="ml-auto"
                disabled={
                  Enum.empty?(@importing_users) ||
                    Enum.any?(@importing_users, fn {_, %{status: status}} -> status == :loading end)
                }
              >
                Import
              </.button>
            </div>

            <div
              :if={map_size(@importing_users) > 0}
              class="space-y-2 max-h-[20rem] overflow-y-auto bg-card rounded-lg p-4 border"
            >
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
                            {Algora.Util.initials(data.user.name || data.user.handle)}
                          </.avatar_fallback>
                        </.avatar>
                        <span class="text-sm font-medium">{data.user.name || data.user.handle}</span>
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
  def handle_event("screen_applicants", _, socket) do
    applicants_without_contributions =
      Enum.filter(socket.assigns.developers, &(socket.assigns.contributions_map |> Map.get(&1.id, []) |> Enum.empty?()))

    socket = enqueue_screening(socket, applicants_without_contributions)

    {:noreply, socket}
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
    applicants =
      socket.assigns.importing_users
      |> Enum.sort_by(fn {_handle, %{order: order}} -> order end)
      |> Enum.filter(fn {_handle, %{status: status, user: user}} ->
        status == :done && not is_nil(user)
      end)
      # TODO: batch this
      |> Enum.flat_map(fn {_handle, %{user: user}} ->
        case Jobs.ensure_application(socket.assigns.job.id, user, %{imported_at: DateTime.utc_now()}) do
          {:ok, _application} -> [user]
          {:error, _} -> []
        end
      end)

    {:noreply,
     socket
     |> push_patch(to: ~p"/#{socket.assigns.job.user.handle}/jobs/#{socket.assigns.job.id}/imports")
     |> put_flash(:info, "Successfully imported applicants")
     |> assign(:show_import_drawer, false)
     |> assign(:importing_users, %{})
     |> assign_applicants()
     |> enqueue_screening(applicants)}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         "/#{socket.assigns.job.user.handle}/jobs/#{socket.assigns.job.id}/#{tab}#{if socket.assigns[:return_to], do: "?return_to=#{socket.assigns.return_to}", else: ""}"
     )}
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
    case Algora.Workspace.ensure_user(Algora.Admin.token(), handle) do
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
  end

  @impl true
  def handle_info({:contributions_fetching, handle}, socket) do
    {:noreply, assign(socket, :loading_contribution_handle, handle)}
  end

  @impl true
  def handle_info({:contributions_fetched, handle, contributions}, socket) do
    if user = Enum.find(socket.assigns.developers, &(&1.provider_login == handle)) do
      {:noreply,
       socket
       |> assign(:contributions_map, Map.put(socket.assigns.contributions_map, user.id, contributions))
       |> assign_applicants()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:contributions_fetched_all}, socket) do
    {:noreply, assign(socket, :loading_contribution_handle, nil)}
  end

  @impl true
  def handle_info({:contributions_failed, _handle}, socket) do
    {:noreply, socket}
  end

  defp assign_applicants(socket) do
    all_applicants = Jobs.list_job_applications(socket.assigns.job)
    applicants = Enum.reject(all_applicants, & &1.imported_at)
    imports = Enum.filter(all_applicants, & &1.imported_at)
    matches = Settings.get_job_matches(socket.assigns.job.id)

    developers = matches |> Enum.concat(all_applicants) |> Enum.map(& &1.user)

    contributions_map = fetch_applicants_contributions(developers, socket.assigns.job.tech_stack)

    socket
    |> assign(:developers, developers)
    |> assign(:applicants, sort_applicants_by_contributions(socket.assigns.job, applicants, contributions_map))
    |> assign(:imports, sort_applicants_by_contributions(socket.assigns.job, imports, contributions_map))
    |> assign(:matches, sort_applicants_by_contributions(socket.assigns.job, matches, contributions_map))
    |> assign(:contributions_map, contributions_map)
  end

  defp enqueue_screening(socket, users) do
    users_without_contributions =
      users
      |> Enum.filter(&(socket.assigns.contributions_map |> Map.get(&1.id, []) |> Enum.empty?()))
      |> Enum.map(& &1.provider_login)

    if Enum.any?(users_without_contributions) do
      Task.start(fn ->
        users_without_contributions
        |> Task.async_stream(
          fn handle ->
            broadcast(socket.assigns.job, {:contributions_fetching, handle})

            with {:ok, contributions} <- Algora.Cloud.top_contributions(handle),
                 :ok <- Algora.Admin.add_contributions(handle, contributions) do
              broadcast(socket.assigns.job, {:contributions_fetched, handle, contributions})
            else
              {:error, reason} ->
                Logger.error("Failed to fetch contributions for #{handle}: #{inspect(reason)}")
                broadcast(socket.assigns.job, {:contributions_failed, handle})
            end
          end,
          timeout: length(users_without_contributions) * 60_000,
          max_concurrency: 3,
          ordered: true
        )
        |> Stream.run()
      end)

      socket
    else
      put_flash(socket, :info, "All applicants have already been screened.")
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

  defp get_matching_tech(contribution, tech_stack) do
    tech_stack = Enum.map(tech_stack, &String.downcase/1)

    Enum.find(contribution.repository.tech_stack, &(String.downcase(&1) in tech_stack)) ||
      List.first(contribution.repository.tech_stack)
  end

  defp developer_card(assigns) do
    ~H"""
    <div class="h-full relative border ring-1 ring-transparent hover:ring-border transition-all bg-card group rounded-xl text-card-foreground shadow p-6">
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
                  {@application.user.name}
                  <span :if={@application.user.country}>
                    {Algora.Misc.CountryEmojis.get(@application.user.country)}
                  </span>
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
                    {Calendar.strftime(
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

        <div :if={@contributions != [] or not is_nil(@loading_contribution_handle)} class="mt-4">
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
                  href={"https://github.com/#{owner.provider_login}/#{List.first(contributions).repository.name}/pulls?q=author%3A#{@application.user.provider_login}+is%3Amerged+"}
                  target="_blank"
                  rel="noopener"
                  class="flex items-center gap-3 rounded-xl pr-2 bg-card/50 border border-border/50 hover:border-border transition-all"
                >
                  <img
                    src={owner.avatar_url}
                    class={
                      classes([
                        "h-12 w-12 rounded-xl rounded-r-none group-hover:saturate-100 transition-all",
                        if(is_nil(@loading_contribution_handle), do: "md:saturate-0")
                      ])
                    }
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
                      <%= if tech = get_matching_tech(List.first(contributions), @tech_stack) do %>
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
                  {@user.name} {Algora.Misc.CountryEmojis.get(@user.country)}
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
                    <%= if tech = get_matching_tech(List.first(contributions), @tech_stack) do %>
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
  defp fetch_applicants_contributions(users, tech_stack) do
    Enum.reduce(users, %{}, fn user, acc ->
      contributions = Algora.Workspace.list_user_contributions(user.provider_login, limit: 20, tech_stack: tech_stack)
      Map.put(acc, user.id, contributions)
    end)
  end

  # Sort applicants by their total number of contributions
  defp sort_applicants_by_contributions(job, applicants, contributions_map) do
    Enum.sort_by(
      applicants,
      fn application ->
        contributions = Map.get(contributions_map, application.user.id, [])

        Enum.reduce(contributions, 0, fn contribution, acc ->
          stars = contribution.repository.stargazers_count
          contribution_count = contribution.contribution_count

          delta =
            if Enum.any?(job.tech_stack, fn tech -> tech in Enum.take(contribution.repository.tech_stack, 1) end) do
              :math.log(stars + 1) * contribution_count
            else
              :math.pow(:math.log(stars + 1) * contribution_count, 0.5)
            end

          acc + delta
        end)
      end,
      :desc
    )
  end

  defp aggregate_contributions(contributions) do
    groups = Enum.group_by(contributions, fn c -> c.repository.user end)

    contributions
    |> Enum.map(fn c -> {c.repository.user, groups[c.repository.user]} end)
    |> Enum.dedup_by(fn {owner, _} -> owner end)
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

  defp social_share_button(assigns) do
    ~H"""
    <.button
      id={@id}
      phx-hook="CopyToClipboard"
      data-value={@value}
      variant="secondary"
      phx-click={
        %JS{}
        |> JS.hide(
          to: "##{@id}-copy-icon",
          transition: {"transition-opacity", "opacity-100", "opacity-0"}
        )
        |> JS.show(
          to: "##{@id}-check-icon",
          transition: {"transition-opacity", "opacity-0", "opacity-100"}
        )
      }
      class="size-6 sm:size-9 relative cursor-pointer text-foreground/90 hover:text-foreground bg-muted"
    >
      <.icon
        id={@id <> "-copy-icon"}
        name={@icon}
        class="absolute inset-0 m-auto size-6 sm:size-6 flex items-center justify-center"
      />
      <.icon
        id={@id <> "-check-icon"}
        name="tabler-check"
        class="absolute inset-0 m-auto hidden size-6 sm:size-6 items-center justify-center"
      />
    </.button>
    """
  end
end
