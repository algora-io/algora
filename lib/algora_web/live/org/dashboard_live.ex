defmodule AlgoraWeb.Org.DashboardLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Achievement
  import AlgoraWeb.Components.Bounties
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Chat
  alias Algora.Contracts
  alias Algora.Github
  alias Algora.Organizations
  alias Algora.Organizations.Member
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Workspace
  alias Algora.Workspace.Contributor
  alias Algora.Workspace.Ticket
  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.Constants
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.ContractForm
  alias AlgoraWeb.Forms.TipForm
  alias AlgoraWeb.LocalStore

  require Logger

  defp list_contributors(%{last_context: "repo/" <> repo} = current_org) do
    case String.split(repo, "/") do
      [repo_owner, repo_name] ->
        Workspace.list_repository_contributors(repo_owner, repo_name)

      _ ->
        if current_org.provider_login, do: Workspace.list_contributors(current_org.provider_login), else: []
    end
  end

  defp list_contributors(%{provider_login: provider_login}) when is_binary(provider_login),
    do: Workspace.list_contributors(provider_login)

  defp list_contributors(_current_org), do: []

  defp get_previewed_user(%{last_context: "repo/" <> repo} = current_org) do
    case String.split(repo, "/") do
      [repo_owner, _repo_name] ->
        Repo.one(from u in User, where: u.provider_login == ^repo_owner and not is_nil(u.handle)) || current_org

      _ ->
        current_org
    end
  end

  defp get_previewed_user(current_org), do: current_org

  @impl true
  def mount(_params, _session, %{assigns: %{live_action: :preview, current_org: nil}} = socket) do
    {:ok, socket}
  end

  @impl true
  def mount(params, _session, socket) do
    %{current_org: current_org} = socket.assigns

    if Member.can_create_bounty?(socket.assigns.current_user_role) do
      previewed_user = get_previewed_user(current_org)

      _experts = Accounts.list_developers(org_id: current_org.id, earnings_gt: Money.zero(:USD))
      experts = []

      installations = Workspace.list_installations_by(connected_user_id: previewed_user.id, provider: "github")

      contributors = list_contributors(current_org)

      matches = Algora.Settings.get_org_matches(previewed_user)

      contributions =
        matches
        |> Enum.map(& &1.user.id)
        |> Algora.Workspace.list_user_contributions()
        |> Enum.group_by(& &1.user.id)

      admins_last_active = Algora.Accounts.admins_last_active()

      developers =
        contributors
        |> Enum.map(& &1.user)
        |> Enum.concat(experts)
        |> Enum.concat(Enum.map(matches, & &1.user))

      oauth_url = Github.authorize_url(%{return_to: "/#{current_org.handle}/dashboard"})

      contracts =
        [org_id: socket.assigns.current_org.id]
        |> Bounties.list_contracts()
        |> Enum.map(fn c ->
          case c.shared_with do
            [user_id] ->
              user = Repo.one(from u in User, where: u.provider_id == ^user_id)
              %{contract: c, user: user}

            _ ->
              nil
          end
        end)
        |> Enum.filter(& &1)

      {:ok,
       socket
       |> assign(:page_title, current_org.name)
       |> assign(
         :page_description,
         "Share bounties, tips or contracts with #{header_prefix(current_org)} contributors and Algora matches"
       )
       |> assign(:screenshot?, not is_nil(params["screenshot"]))
       |> assign(:pending_action, nil)
       |> assign(:ip_address, AlgoraWeb.Util.get_ip(socket))
       |> assign(:admins_last_active, admins_last_active)
       |> assign(:has_fresh_token?, Accounts.has_fresh_token?(socket.assigns.current_user))
       |> assign(:installations, installations)
       |> assign(:experts, experts)
       |> assign(:contributors, contributors)
       |> assign(:previewed_user, previewed_user)
       |> assign(:contracts, contracts)
       |> assign(:matches, matches)
       |> assign(:contributions, contributions)
       |> assign(:developers, developers)
       |> assign(:has_more_bounties, false)
       |> assign(:oauth_url, oauth_url)
       |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
       |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
       |> assign(:contract_form, to_form(ContractForm.changeset(%ContractForm{}, %{})))
       |> assign(:show_share_drawer, false)
       |> assign(:share_drawer_type, nil)
       |> assign(:selected_developer, nil)
       |> assign(:secret, nil)
       |> assign_login_form(User.login_changeset(%User{}, %{}))
       |> assign_payable_bounties()
       |> assign_achievements()
       # Will be initialized when chat starts
       |> assign(:thread, nil)
       |> assign(:messages, [])
       |> assign(:show_chat, false)}
    else
      {:ok, redirect(socket, to: ~p"/#{current_org.handle}/home")}
    end
  end

  @impl true
  def handle_params(_params, _uri, %{assigns: %{live_action: :preview, current_org: nil}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      if params["action"] == "create_contract" do
        assign(socket, :main_contract_form_open?, true)
      else
        socket
      end

    # Create login changeset with email from params if present
    socket =
      if email = params["email"] do
        login_changeset = User.login_changeset(%User{}, %{email: email})
        assign_login_form(socket, login_changeset)
      else
        socket
      end

    {:noreply,
     socket
     |> LocalStore.init(key: __MODULE__)
     |> LocalStore.subscribe()
     |> assign_bounties()}
  end

  @impl true
  def render(%{current_user: nil, live_action: :preview} = assigns) do
    ~H"""
    <div class="w-screen h-screen fixed inset-0 bg-background z-[100]">
      <div class="flex items-center justify-center h-full">
        <svg
          class="mr-3 -ml-1 size-12 animate-spin text-success"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
          </circle>
          <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          >
          </path>
        </svg>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="lg:pr-96" id="org-dashboard" phx-hook="LocalStateStore">
      <div class="container mx-auto max-w-7xl space-y-8 xl:space-y-16 p-4 sm:p-6 lg:p-8">
        <.section :if={@payable_bounties != %{}}>
          <.card>
            <.card_header>
              <.card_title>Pending Payments</.card_title>
              <.card_description>
                The following claims have been approved and are ready for payment.
              </.card_description>
            </.card_header>
            <.card_content class="p-0">
              <table class="w-full caption-bottom text-sm overflow-x-auto">
                <tbody class="[&_tr:last-child]:border-0">
                  <%= for {_group_id, [%{target: %{bounties: [bounty | _]}} | _] = claims} <- @payable_bounties do %>
                    <tr
                      class="bg-white/[2%] from-white/[2%] via-white/[2%] to-white/[2%] border-b border-white/15 bg-gradient-to-br transition-colors data-[state=selected]:bg-gray-100 hover:bg-gray-100/50 dark:data-[state=selected]:bg-gray-800 dark:hover:bg-white/[2%]"
                      data-state="false"
                    >
                      <td colspan={2} class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
                        <div class="md:min-w-[250px]">
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
                    </tr>
                    <tr
                      class="border-b border-white/15 bg-gray-950/50 transition-colors data-[state=selected]:bg-gray-100 hover:bg-gray-100/50 dark:data-[state=selected]:bg-gray-800 dark:hover:bg-gray-950/50"
                      data-state="false"
                    >
                      <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle w-full">
                        <div class="md:min-w-[250px]">
                          <div class="flex items-center gap-3">
                            <div class="flex -space-x-3">
                              <%= for claim <- claims do %>
                                <div class="relative h-10 w-10 flex-shrink-0 rounded-full ring-4 ring-background">
                                  <img
                                    alt={User.handle(claim.user)}
                                    loading="lazy"
                                    decoding="async"
                                    class="rounded-full"
                                    src={claim.user.avatar_url}
                                    style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                                  />
                                </div>
                              <% end %>
                            </div>
                            <div>
                              <div class="text-sm font-medium text-gray-200 line-clamp-1">
                                {claims
                                |> Enum.map(fn c -> User.handle(c.user) end)
                                |> Algora.Util.format_name_list()}
                              </div>
                              <div class="text-xs text-gray-400">
                                {Algora.Util.time_ago(hd(claims).inserted_at)}
                              </div>
                            </div>
                          </div>
                          <div class="pt-4 flex items-center md:hidden gap-4">
                            <.button
                              :if={hd(claims).source}
                              href={hd(claims).source.url}
                              variant="secondary"
                            >
                              View
                            </.button>
                            <.button href={~p"/claims/#{hd(claims).group_id}"}>
                              Reward
                            </.button>
                          </div>
                        </div>
                      </td>
                      <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle hidden md:table-cell">
                        <div class="md:min-w-[180px]">
                          <div class="flex items-center justify-end gap-4">
                            <.button
                              :if={hd(claims).source}
                              href={hd(claims).source.url}
                              variant="secondary"
                            >
                              View
                            </.button>
                            <.button href={~p"/claims/#{hd(claims).group_id}"}>
                              Reward
                            </.button>
                          </div>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </.card_content>
          </.card>
        </.section>

        <.section
          :if={length(@contracts) > 0}
          title="Active contracts"
          subtitle="List of your ongoing contracts"
        >
          <div class="-ml-4">
            <div class="relative w-full overflow-auto">
              <table class="w-full caption-bottom text-sm">
                <tbody>
                  <%= for %{contract: contract, user: user} <- @contracts do %>
                    <.contract_card contract={contract} user={user} />
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </.section>

        <.section
          :if={@contributors != []}
          title={"#{header_prefix(@previewed_user)} Contributors"}
          subtitle="Share bounties, tips or contract opportunities with your top contributors"
        >
          <div class="relative w-full overflow-auto max-h-[250px] scrollbar-thin">
            <table class="w-full caption-bottom text-sm">
              <tbody>
                <%= for %Contributor{user: user} <- @contributors do %>
                  <.developer_card
                    user={user}
                    contract_for_user={contract_for_user(@contracts, user)}
                    contract_type={
                      if(Enum.find(@matches, &(&1.user.id == user.id)),
                        do: "marketplace",
                        else: "bring_your_own"
                      )
                    }
                    current_org={@current_org}
                  />
                <% end %>
              </tbody>
            </table>
          </div>
        </.section>

        <div
          :if={length(@achievements) > 1}
          class="lg:hidden border ring-1 ring-transparent rounded-xl overflow-hidden"
        >
          <div class="bg-card/75 flex flex-col h-full p-4 rounded-xl border-t-4 sm:border-t-0 sm:border-l-4 border-emerald-400">
            <div class="p-4 sm:p-6">
              <.getting_started
                id="getting_started_main"
                achievements={
                  if incomplete?(@achievements, :complete_signin_status) or
                       incomplete?(@achievements, :complete_signup_status),
                     do: @achievements |> Enum.take(1),
                     else: @achievements
                }
                current_user={@current_user}
                current_org={@current_org}
                secret={@secret}
                login_form={@login_form}
                previewed_user={@previewed_user}
              />
            </div>
          </div>
        </div>

        <%!-- <.section
          :if={@matches != []}
          title="Algora Matches"
          subtitle="Top 1% Algora developers in your tech stack available to hire now"
        >
          <div class="relative w-full flex flex-col gap-4">
            <div :if={!@screenshot?} class="lg:pb-2 lg:pt-4 flex flex-col lg:flex-row gap-4 lg:gap-4">
              <h3 class="text-lg font-semibold whitespace-nowrap">How it works</h3>
              <ul class="xl:mx-auto flex flex-col md:flex-row gap-2 md:gap-4 2xl:gap-6 text-xs font-medium">
                <li class="flex items-center">
                  <.icon name="tabler-circle-number-1 mr-2" class="size-6 text-success-400 shrink-0" />
                  Authorize payment to send offer
                </li>
                <li class="flex items-center">
                  <.icon name="tabler-circle-number-2 mr-2" class="size-6 text-success-400 shrink-0" />
                  Escrowed when developer accepts
                </li>
                <li class="flex items-center">
                  <.icon name="tabler-circle-number-3 mr-2" class="size-6 text-success-400 shrink-0" />
                  Release/withhold escrow as you go
                </li>
              </ul>
            </div>
            <%= for match <- @matches do %>
              <.match_card
                match={match}
                contract_for_user={contract_for_user(@contracts, match.user)}
                contributions={@contributions[match.user.id]}
                current_org={@current_org}
              />
            <% end %>
          </div>
        </.section> --%>

        <.section
          :if={@experts != []}
          title="Algora Experts"
          subtitle="Meet Algora experts versed in your tech stack"
        >
          <div class="relative w-full overflow-auto max-h-[400px] scrollbar-thin">
            <table class="w-full caption-bottom text-sm">
              <tbody>
                <%= for user <- @experts do %>
                  <.developer_card
                    user={user}
                    contract_for_user={contract_for_user(@contracts, user)}
                    contract_type={
                      if(Enum.find(@matches, &(&1.user.id == user.id)),
                        do: "marketplace",
                        else: "bring_your_own"
                      )
                    }
                    current_org={@current_org}
                  />
                <% end %>
              </tbody>
            </table>
          </div>
        </.section>

        <div id="bounties-container" phx-hook="InfiniteScroll">
          <div class="mb-2">
            <div class="flex flex-wrap items-start justify-between gap-4 lg:flex-nowrap">
              <div>
                <h2 class="text-2xl font-bold dark:text-white">
                  {header_prefix(@previewed_user)} Bounties
                </h2>
                <p class="text-sm dark:text-gray-300">
                  Create new bounties by commenting
                  <code class="mx-1 inline-block rounded bg-emerald-950/75 px-1 py-0.5 font-mono text-sm text-emerald-400 ring-1 ring-emerald-400/25">
                    /bounty $1000
                  </code>
                  on GitHub issues.
                </p>
              </div>
            </div>
          </div>
          <div class="relative">
            <%= if Enum.empty?(@bounty_rows) do %>
              <.card class="rounded-lg bg-card py-12 text-center lg:rounded-[2rem]">
                <.card_header>
                  <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                    <.icon name="tabler-diamond" class="h-8 w-8 text-muted-foreground" />
                  </div>
                  <.card_title>No bounties yet</.card_title>
                  <.card_description class="pt-2">
                    <%= if @installations == [] do %>
                      Install Algora in {@current_org.name} to create new bounties by commenting
                      <code class="mx-1 inline-block rounded bg-emerald-950/75 px-1 py-0.5 font-mono text-sm text-emerald-400 ring-1 ring-emerald-400/25">
                        /bounty $1000
                      </code>
                      on GitHub issues
                      <.button
                        :if={@installations == []}
                        phx-click="install_app"
                        class="mt-4 flex mx-auto"
                      >
                        <Logos.github class="w-4 h-4 mr-2 -ml-1" /> Install Algora
                      </.button>
                    <% else %>
                      Create new bounties by commenting
                      <code class="mx-1 inline-block rounded bg-emerald-950/75 px-1 py-0.5 font-mono text-sm text-emerald-400 ring-1 ring-emerald-400/25">
                        /bounty $1000
                      </code>
                      on GitHub issues
                    <% end %>
                  </.card_description>
                </.card_header>
              </.card>
            <% else %>
              <div id="bounties-container" phx-hook="InfiniteScroll">
                <.bounties bounties={@bounty_rows} />
                <div
                  :if={@has_more_bounties}
                  class="flex justify-center mt-4"
                  data-load-more-indicator
                >
                  <div class="animate-pulse text-muted-foreground">
                    <.icon name="tabler-loader" class="h-6 w-6 animate-spin" />
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <.section
          title={"#{header_prefix(@previewed_user)} Ecosystem"}
          subtitle="Help maintain and grow your ecosystem by creating bounties and tips in your dependencies"
        >
          <div class="flex flex-col gap-4">
            {create_bounty(assigns)}
            {create_tip(assigns)}
          </div>
        </.section>
      </div>
    </div>
    <.sidebar
      admins_last_active={@admins_last_active}
      achievements={@achievements}
      current_user={@current_user}
      current_org={@current_org}
      secret={@secret}
      login_form={@login_form}
      previewed_user={@previewed_user}
      show_chat={@show_chat}
      messages={@messages}
    />
    {share_drawer(assigns)}
    """
  end

  @impl true
  def handle_info(%Chat.MessageCreated{message: message}, socket) do
    if message.id in Enum.map(socket.assigns.messages, & &1.id) do
      {:noreply, socket}
    else
      {:noreply, Phoenix.Component.update(socket, :messages, &(&1 ++ [message]))}
    end
  end

  def handle_event("restore_settings", params, socket) do
    socket = LocalStore.restore(socket, params)

    case socket.assigns.pending_action do
      nil ->
        {:noreply, socket}

      {event, params} ->
        socket = LocalStore.assign_cached(socket, :pending_action, nil)
        handle_event(event, params, socket)
    end
  end

  @impl true
  def handle_event("install_app" = event, unsigned_params, socket) do
    {:noreply,
     if socket.assigns.has_fresh_token? do
       redirect(socket, external: Github.install_url_select_target())
     else
       socket
       |> LocalStore.assign_cached(:pending_action, {event, unsigned_params})
       |> redirect(external: socket.assigns.oauth_url)
     end}
  end

  @impl true
  def handle_event("remove_contributor", %{"user_id" => user_id}, socket) do
    current_org = socket.assigns.current_org

    if incomplete?(socket.assigns.achievements, :install_app_status) do
      {:noreply, put_flash(socket, :error, "Please install the app first")}
    else
      Repo.delete_all(
        from c in Contributor,
          where: c.user_id == ^user_id,
          join: r in assoc(c, :repository),
          join: u in assoc(r, :user),
          where: u.provider == ^current_org.provider and u.provider_id == ^current_org.provider_id
      )

      contributors = Enum.reject(socket.assigns.contributors, &(&1.user.id == user_id))
      {:noreply, assign(socket, :contributors, contributors)}
    end
  end

  def handle_event("create_bounty" = event, %{"bounty_form" => params} = unsigned_params, socket) do
    if socket.assigns.has_fresh_token? do
      changeset = %BountyForm{} |> BountyForm.changeset(params) |> Map.put(:action, :validate)

      amount = get_field(changeset, :amount)
      ticket_ref = get_field(changeset, :ticket_ref)

      with %{valid?: true} <- changeset,
           {:ok, _bounty} <-
             Bounties.create_bounty(
               %{
                 creator: socket.assigns.current_user,
                 owner: socket.assigns.current_org,
                 amount: amount,
                 ticket_ref: %{
                   owner: ticket_ref.owner,
                   repo: ticket_ref.repo,
                   number: ticket_ref.number
                 }
               },
               visibility: get_field(changeset, :visibility),
               shared_with: get_field(changeset, :shared_with)
             ) do
        {:noreply,
         socket
         |> assign_achievements()
         |> assign_bounties()
         |> put_flash(:info, "Bounty created")}
      else
        %{valid?: false} ->
          {:noreply, assign(socket, :bounty_form, to_form(changeset))}

        {:error, :already_exists} ->
          {:noreply, put_flash(socket, :warning, "You already have a bounty for this ticket")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Something went wrong")}
      end
    else
      {:noreply,
       socket
       |> LocalStore.assign_cached(:pending_action, {event, unsigned_params})
       |> redirect(external: socket.assigns.oauth_url)}
    end
  end

  @impl true
  def handle_event("create_tip" = event, %{"tip_form" => params} = unsigned_params, socket) do
    if socket.assigns.has_fresh_token? do
      changeset = %TipForm{} |> TipForm.changeset(params) |> Map.put(:action, :validate)

      ticket_ref = get_field(changeset, :ticket_ref)

      with %{valid?: true} <- changeset,
           {:ok, token} <- Accounts.get_access_token(socket.assigns.current_user),
           {:ok, recipient} <- Workspace.ensure_user(token, get_field(changeset, :github_handle)),
           {:ok, checkout_url} <-
             Bounties.create_tip(
               %{
                 creator: socket.assigns.current_user,
                 owner: socket.assigns.current_org,
                 recipient: recipient,
                 amount: get_field(changeset, :amount)
               },
               ticket_ref: %{
                 owner: ticket_ref.owner,
                 repo: ticket_ref.repo,
                 number: ticket_ref.number
               }
             ) do
        {:noreply, redirect(socket, external: checkout_url)}
      else
        %{valid?: false} ->
          {:noreply, assign(socket, :tip_form, to_form(changeset))}

        {:error, reason} ->
          Logger.error("Failed to create tip: #{inspect(reason)}")
          {:noreply, put_flash(socket, :error, "Something went wrong")}
      end
    else
      {:noreply,
       socket
       |> LocalStore.assign_cached(:pending_action, {event, unsigned_params})
       |> redirect(external: socket.assigns.oauth_url)}
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
    hours_per_week = match[:hours_per_week] || developer.hours_per_week || 30

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
         title: "#{socket.assigns.current_org.name} Development",
         description: "Contribution to #{socket.assigns.current_org.name} for #{hours_per_week} hours"
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
  def handle_event("share_opportunity", _params, socket) do
    {:noreply, put_flash(socket, :error, "Please select a developer first")}
  end

  @impl true
  def handle_event("close_share_drawer", _params, socket) do
    {:noreply, assign(socket, :show_share_drawer, false)}
  end

  @impl true
  def handle_event("create_contract", %{"contract_form" => params}, socket) do
    changeset = ContractForm.changeset(%ContractForm{}, params)

    case apply_action(changeset, :save) do
      {:ok, data} ->
        contract_params = %{
          client_id: socket.assigns.current_org.id,
          contractor_id: socket.assigns.selected_developer.id,
          hourly_rate: data.hourly_rate,
          hours_per_week: data.hours_per_week,
          status: :draft
        }

        case Contracts.create_contract(contract_params) do
          {:ok, contract} ->
            Algora.Activities.alert(
              "Contract offer from #{socket.assigns.current_org.handle} to #{socket.assigns.selected_developer.handle} for #{data.hourly_rate}/hour x #{data.hours_per_week} hours/week. ID: #{contract.id}"
            )

            {:noreply,
             socket
             |> assign(:show_share_drawer, false)
             |> redirect(to: ~p"/#{socket.assigns.current_org.handle}/contracts/#{contract.id}")}

          {:error, changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to create contract: #{inspect(changeset.errors)}")}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, :contract_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("send_login_code", %{"user" => %{"email" => email}}, socket) do
    {secret, code} = AlgoraWeb.UserAuth.generate_totp()

    changeset = User.login_changeset(%User{}, %{})

    case Accounts.deliver_totp_signup_email(email, code) do
      {:ok, _id} ->
        {:noreply,
         socket
         |> assign(:secret, secret)
         |> assign(:email, email)
         |> assign_login_form(changeset)}

      {:error, reason} ->
        Logger.error("Failed to send login code to #{email}: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "We had trouble sending mail to #{email}. Please try again")}
    end
  end

  @impl true
  def handle_event("send_login_code", %{"user" => %{"login_code" => code}}, socket) do
    case AlgoraWeb.UserAuth.verify_totp(socket.assigns.ip_address, socket.assigns.secret, String.trim(code)) do
      :ok ->
        handle =
          socket.assigns.email
          |> Organizations.generate_handle_from_email()
          |> Organizations.ensure_unique_handle()

        case Repo.get_by(User, email: socket.assigns.email) do
          nil ->
            {:ok, user} =
              socket.assigns.current_user
              |> Ecto.Changeset.change(handle: handle, email: socket.assigns.email)
              |> Repo.update()

            autojoined? =
              user
              |> Accounts.auto_join_orgs()
              |> Enum.any?(&(&1.id == socket.assigns.previewed_user.id))

            socket =
              if autojoined? do
                switch_from_preview(socket, user)
              else
                socket
                |> assign(:current_user, user)
                |> assign_achievements()
              end

            {:noreply, socket}

          user ->
            socket = switch_from_preview(socket, user)
            {:noreply, socket}
        end

      {:error, :rate_limit_exceeded} ->
        throttle()
        {:noreply, put_flash(socket, :error, "Too many attempts. Please try again later.")}

      {:error, :invalid_totp} ->
        throttle()
        {:noreply, put_flash(socket, :error, "Invalid login code")}
    end
  end

  @impl true
  def handle_event("change-tab", %{"tab" => "completed"}, socket) do
    {:noreply, push_patch(socket, to: ~p"/#{socket.assigns.current_org.handle}/dashboard?status=completed")}
  end

  @impl true
  def handle_event("change-tab", %{"tab" => "open"}, socket) do
    {:noreply, push_patch(socket, to: ~p"/#{socket.assigns.current_org.handle}/dashboard?status=open")}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    {:noreply, assign_more_bounties(socket)}
  end

  @impl true
  def handle_event("start_chat", _params, socket) do
    # Get or create thread between user and founders
    {:ok, thread} = Chat.get_or_create_admin_thread(socket.assigns.current_user)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Algora.PubSub, "chat:thread:#{thread.id}")
    end

    messages = thread.id |> Chat.list_messages() |> Repo.preload(:sender)

    {:noreply,
     socket
     |> assign(:thread, thread)
     |> assign(:messages, messages)
     |> assign(:show_chat, true)}
  end

  @impl true
  def handle_event("close_chat", _params, socket) do
    {:noreply, assign(socket, :show_chat, false)}
  end

  @impl true
  def handle_event("send_message", %{"message" => content}, socket) do
    {:ok, message} =
      Chat.send_message(
        socket.assigns.thread.id,
        socket.assigns.current_user.id,
        content
      )

    message = Repo.preload(message, :sender)

    {:noreply,
     socket
     |> Phoenix.Component.update(:messages, &(&1 ++ [message]))
     |> push_event("clear-input", %{selector: "#message-input"})}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp switch_from_preview(socket, user) do
    current_user = socket.assigns.current_user

    existing_member =
      case socket.assigns.current_org do
        %{last_context: "repo/" <> repo} ->
          case String.split(repo, "/") do
            [repo_owner, _repo_name] ->
              Repo.one(
                from m in Member,
                  where: m.user_id == ^user.id,
                  join: o in assoc(m, :org),
                  where: o.provider_login == ^repo_owner,
                  preload: [org: o]
              )

            _ ->
              nil
          end

        _ ->
          nil
      end

    if existing_member do
      Accounts.update_settings(user, %{last_context: existing_member.org.handle})
    else
      case Repo.get_by(Member, user_id: current_user.id, org_id: socket.assigns.current_org.id) do
        nil -> {:ok, nil}
        member -> member |> change(user_id: user.id) |> Repo.update()
      end

      Accounts.update_settings(user, %{last_context: current_user.last_context})
    end

    redirect(socket, to: AlgoraWeb.UserAuth.generate_login_path(user.email))
  end

  defp throttle, do: :timer.sleep(1000)

  defp assign_login_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :login_form, to_form(changeset))
  end

  defp to_bounty_rows(bounties), do: bounties

  defp assign_bounties(socket) do
    stats = Bounties.fetch_stats(org_id: socket.assigns.previewed_user.id, current_user: socket.assigns[:current_user])

    bounties =
      Bounties.list_bounties(
        owner_id: socket.assigns.previewed_user.id,
        limit: page_size(),
        status: :open,
        current_user: socket.assigns[:current_user]
      )

    socket
    |> assign(:bounty_rows, to_bounty_rows(bounties))
    |> assign(:has_more_bounties, length(bounties) >= page_size())
    |> assign(:stats, stats)
  end

  defp assign_more_bounties(socket) do
    %{bounty_rows: rows} = socket.assigns

    last_bounty = List.last(rows)

    cursor = %{
      inserted_at: last_bounty.inserted_at,
      id: last_bounty.id
    }

    more_bounties =
      Bounties.list_bounties(
        owner_id: socket.assigns.previewed_user.id,
        limit: page_size(),
        status: :open,
        before: cursor,
        current_user: socket.assigns[:current_user]
      )

    socket
    |> assign(:bounty_rows, rows ++ to_bounty_rows(more_bounties))
    |> assign(:has_more_bounties, length(more_bounties) >= page_size())
  end

  defp page_size, do: 10

  defp assign_payable_bounties(socket) do
    org = socket.assigns.current_org

    paid_bounties_query =
      from b in Bounty,
        join: t in Transaction,
        on: t.bounty_id == b.id,
        where: t.type == :debit,
        where: t.status == :succeeded,
        where: t.user_id == ^org.id,
        select: b.id

    payable_claims =
      Repo.all(
        from c in Claim,
          where: c.status == :approved,
          join: b in Bounty,
          on: b.ticket_id == c.target_id and b.owner_id == ^org.id,
          where: b.id not in subquery(paid_bounties_query),
          join: t in assoc(c, :target),
          join: r in assoc(t, :repository),
          join: ru in assoc(r, :user),
          join: cu in assoc(c, :user),
          left_join: s in assoc(c, :source),
          distinct: b.id,
          select_merge: %{
            user: cu,
            source: s,
            target: %Ticket{t | bounties: [%Bounty{b | ticket: %{t | repository: %{r | user: ru}}}]}
          }
      )

    payable_bounties = Enum.group_by(payable_claims, & &1.group_id)
    assign(socket, :payable_bounties, payable_bounties)
  end

  defp achievement_todo(%{achievement: %{status: status}} = assigns) when status != :current do
    ~H"""
    """
  end

  defp achievement_todo(%{achievement: %{id: :complete_signup_status}} = assigns) do
    ~H"""
    <.simple_form :if={!@secret} for={@login_form} phx-submit="send_login_code">
      <.input
        id={@id <> "_user_email"}
        field={@login_form[:email]}
        type="email"
        label="Email"
        placeholder="you@example.com"
        required
      />
      <.button phx-disable-with="Signing up..." class="w-full py-5">
        Sign up
      </.button>
    </.simple_form>
    <.simple_form :if={@secret} for={@login_form} phx-submit="send_login_code">
      <.input
        id={@id <> "_user_login_code"}
        field={@login_form[:login_code]}
        type="text"
        label="Login code"
        placeholder="123456"
        required
      />
      <.button phx-disable-with="Signing in..." class="w-full py-5">
        ✨ Get in ✨
      </.button>
    </.simple_form>
    """
  end

  defp achievement_todo(%{achievement: %{id: :complete_signin_status}} = assigns) do
    ~H"""
    <.simple_form :if={!@secret} for={@login_form} phx-submit="send_login_code">
      <.input
        id={@id <> "_user_email"}
        field={@login_form[:email]}
        type="email"
        label="Email"
        placeholder="you@example.com"
        required
      />
      <.button phx-disable-with="Signing in..." class="w-full py-5">
        Sign in
      </.button>
    </.simple_form>
    <.simple_form :if={@secret} for={@login_form} phx-submit="send_login_code">
      <.input
        id={@id <> "_user_login_code"}
        field={@login_form[:login_code]}
        type="text"
        label="Login code"
        placeholder="123456"
        required
      />
      <.button phx-disable-with="Signing in..." class="w-full py-5">
        ✨ Get in ✨
      </.button>
    </.simple_form>
    """
  end

  defp achievement_todo(%{achievement: %{id: :connect_github_status}} = assigns) do
    ~H"""
    <.button :if={!@current_user.provider_login} href={Github.authorize_url()} class="ml-auto gap-2">
      <Logos.github class="w-4 h-4 -ml-1" /> Connect GitHub
    </.button>
    """
  end

  defp achievement_todo(%{achievement: %{id: :install_app_status}} = assigns) do
    ~H"""
    <.button phx-click="install_app" class="ml-auto gap-2">
      <Logos.github class="w-4 h-4 -ml-1" /> Install GitHub App
    </.button>
    """
  end

  defp achievement_todo(assigns) do
    ~H"""
    """
  end

  defp assign_achievements(socket) do
    previewed_user = socket.assigns.previewed_user
    current_org = socket.assigns.current_org

    status_fns =
      if previewed_user == current_org do
        [
          {&personalize_status/1, "Personalize Algora", nil},
          {&complete_signup_status/1, "Complete signup", nil},
          {&connect_github_status/1, "Connect GitHub", nil},
          {&install_app_status/1, "Install Algora in #{previewed_user.name}", nil},
          {&create_bounty_status/1, "Create a bounty", nil},
          {&reward_bounty_status/1, "Reward a bounty", nil},
          {&create_contract_status/1, "Contract a developer",
           if(previewed_user.handle, do: [patch: ~p"/#{previewed_user.handle}/dashboard?action=create_contract"])},
          {&embed_algora_status/1, "Embed Algora", "/docs/embed/sdk"},
          {&share_with_friend_status/1, "Share Algora with a friend", nil}
        ]
      else
        [
          {&complete_signin_status/1, "Sign in to your account", nil},
          {&connect_github_status/1, "Connect GitHub", nil},
          {&install_app_status/1, "Install Algora in #{previewed_user.name}", nil},
          {&create_bounty_status/1, "Create a bounty", nil},
          {&reward_bounty_status/1, "Reward a bounty", nil},
          {&create_contract_status/1, "Contract a developer",
           if(previewed_user.handle, do: [patch: ~p"/#{previewed_user.handle}/dashboard?action=create_contract"])},
          {&embed_algora_status/1, "Embed Algora", "/docs/embed/sdk"},
          {&share_with_friend_status/1, "Share Algora with a friend", nil}
        ]
      end

    {achievements, _} =
      Enum.reduce_while(status_fns, {[], false}, fn {status_fn, name, path}, {acc, found_current} ->
        id = Function.info(status_fn)[:name]
        status = status_fn.(socket)

        result =
          cond do
            found_current -> {acc ++ [%{id: id, status: status, name: name, path: path}], found_current}
            status == :completed -> {acc ++ [%{id: id, status: status, name: name, path: path}], false}
            true -> {acc ++ [%{id: id, status: :current, name: name, path: path}], true}
          end

        {:cont, result}
      end)

    assign(socket, :achievements, Enum.reject(achievements, &(&1.status == :completed)))
  end

  defp incomplete?(achievements, id) do
    Enum.any?(achievements, &(&1.id == id and &1.status != :completed))
  end

  defp personalize_status(_socket), do: :completed

  defp complete_signup_status(socket) do
    case socket.assigns.current_user do
      %User{handle: handle} when is_binary(handle) -> :completed
      _ -> :upcoming
    end
  end

  defp complete_signin_status(socket) do
    case socket.assigns.current_user do
      %User{handle: handle} when is_binary(handle) -> :completed
      _ -> :upcoming
    end
  end

  defp connect_github_status(socket) do
    case socket.assigns.current_user do
      %User{provider_login: login} when is_binary(login) -> :completed
      _ -> :upcoming
    end
  end

  defp install_app_status(socket) do
    case socket.assigns.installations do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp create_bounty_status(socket) do
    case Bounties.list_bounties(owner_id: socket.assigns.previewed_user.id, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp reward_bounty_status(socket) do
    case Bounties.list_bounties(owner_id: socket.assigns.previewed_user.id, status: :paid, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp create_contract_status(socket) do
    case socket.assigns.contracts do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp embed_algora_status(_socket), do: :upcoming
  defp share_with_friend_status(_socket), do: :upcoming

  defp contract_card(assigns) do
    ~H"""
    <tr class="border-b transition-colors hover:bg-muted/10">
      <td class="p-4 align-middle">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div class="flex flex-col sm:flex-row gap-4">
            <div>
              <div class="flex items-center -space-x-2">
                <.avatar class="aspect-square h-12 w-auto rounded-lg ring-2 ring-black">
                  <.avatar_image
                    src={@contract.owner.og_image_url || @contract.owner.avatar_url}
                    alt={@contract.owner.name}
                    class="object-cover bg-transparent"
                  />
                  <.avatar_fallback class="rounded-lg">
                    {Algora.Util.initials(@contract.owner.name)}
                  </.avatar_fallback>
                </.avatar>
                <.avatar class="aspect-square h-12 w-auto rounded-full ring-2 ring-black">
                  <.avatar_image
                    src={@user.avatar_url}
                    alt={@user.name}
                    class="object-cover bg-transparent"
                  />
                  <.avatar_fallback class="rounded-lg">
                    {Algora.Util.initials(@user.name)}
                  </.avatar_fallback>
                </.avatar>
              </div>
            </div>

            <div class="flex flex-col gap-1">
              <div class="flex items-center gap-1 text-base text-foreground">
                <.link
                  navigate={~p"/#{@contract.owner.handle}/contracts/#{@contract.id}"}
                  class="font-semibold hover:underline"
                >
                  {@contract.ticket.title}
                </.link>
              </div>
              <div class="line-clamp-2 text-muted-foreground">
                {@contract.ticket.description}
              </div>
              <div class="mt-1 flex flex-wrap gap-2 saturate-0">
                <%= for tech <- @contract.owner.tech_stack || [] do %>
                  <.tech_badge tech={String.capitalize(tech)} />
                <% end %>
              </div>
            </div>
          </div>

          <div class="flex flex-col items-start sm:items-end gap-3">
            <div class="hidden sm:block sm:text-right">
              <div class="whitespace-nowrap text-sm text-muted-foreground">Total contract value</div>
              <div class="font-display text-lg font-semibold text-foreground">
                {Money.to_string!(@contract.amount)} / wk
              </div>
            </div>
            <.button
              navigate={~p"/#{@contract.owner.handle}/contracts/#{@contract.id}"}
              phx-click="view_contract"
              phx-value-org={@contract.owner.handle}
              size="sm"
            >
              View contract
            </.button>
          </div>
        </div>
      </td>
    </tr>
    """
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
                  {@user.name}
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
                  <Logos.github class="shrink-0 h-4 w-4" />
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

              <%!-- <div class="pt-1.5 flex flex-wrap gap-2">
                <%= for tech <- @user.tech_stack do %>
                  <div class="rounded-lg bg-foreground/5 px-2 py-1 text-xs font-medium text-foreground ring-1 ring-inset ring-foreground/25">
                    {tech}
                  </div>
                <% end %>
              </div> --%>
            </div>
          </div>
          <div class="flex gap-2">
            <.button
              phx-click="share_opportunity"
              phx-value-user_id={@user.id}
              phx-value-type="bounty"
              variant="none"
              class="group bg-blue-900/10 text-blue-300 transition-colors duration-75 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border border-blue-400/40 hover:border-blue-400/50 focus:border-blue-400/50"
            >
              <.icon name="tabler-diamond" class="size-4 text-current mr-2 -ml-1" /> Bounty
            </.button>
            <.button
              phx-click="share_opportunity"
              phx-value-user_id={@user.id}
              phx-value-type="tip"
              variant="none"
              class="group bg-red-900/10 text-red-300 transition-colors duration-75 hover:bg-red-800/10 hover:text-red-300 hover:drop-shadow-[0_1px_5px_#f8717180] focus:bg-red-800/10 focus:text-red-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#f8717180] border border-red-400/40 hover:border-red-400/50 focus:border-red-400/50"
            >
              <.icon name="tabler-heart" class="size-4 text-current mr-2 -ml-1" /> Tip
            </.button>

            <.button
              :if={@contract_for_user && @contract_for_user.status in [:active, :paid]}
              navigate={~p"/#{@current_org.handle}/contracts/#{@contract_for_user.id}"}
              variant="none"
              class="bg-emerald-800/10 text-emerald-300 drop-shadow-[0_1px_5px_#34d39980] focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border border-emerald-400/50 focus:border-emerald-400/50"
            >
              <.icon name="tabler-contract" class="size-4 text-current mr-2 -ml-1" /> Contract
            </.button>
            <.button
              :if={@contract_for_user && @contract_for_user.status in [:draft]}
              navigate={~p"/#{@current_org.handle}/contracts/#{@contract_for_user.id}"}
              variant="none"
              class="bg-gray-800/10 text-gray-400 drop-shadow-[0_1px_5px_#94a3b880] focus:bg-gray-800/10 focus:text-gray-400 focus:outline-none focus:drop-shadow-[0_1px_5px_#94a3b880] border border-gray-400/50 focus:border-gray-400/50"
            >
              <.icon name="tabler-clock" class="size-4 text-current mr-2 -ml-1" /> Contract
            </.button>
            <.button
              :if={!@contract_for_user}
              phx-click="share_opportunity"
              phx-value-user_id={@user.id}
              phx-value-type="contract"
              phx-value-contract_type={@contract_type}
              variant="none"
              class="group bg-emerald-900/10 text-emerald-300 transition-colors duration-75 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border border-emerald-400/40 hover:border-emerald-400/50 focus:border-emerald-400/50"
            >
              <.icon name="tabler-contract" class="size-4 text-current mr-2 -ml-1" /> Contract
            </.button>
            <%!-- <.dropdown_menu>
              <.dropdown_menu_trigger>
                <.button variant="ghost" size="icon">
                  <.icon name="tabler-dots" class="h-4 w-4" />
                </.button>
              </.dropdown_menu_trigger>
              <.dropdown_menu_content>
                <.dropdown_menu_item>
                  <.link href={User.url(@user)}>
                    View Profile
                  </.link>
                </.dropdown_menu_item>
                <.dropdown_menu_separator />
                <.dropdown_menu_item phx-click="remove_contributor" phx-value-user_id={@user.id}>
                  Remove
                </.dropdown_menu_item>
              </.dropdown_menu_content>
            </.dropdown_menu> --%>
          </div>
        </div>
      </td>
    </tr>
    """
  end


  defp contract_for_user(_contracts, _user) do
    nil
  end

  defp create_bounty(assigns) do
    ~H"""
    <div class="border ring-1 ring-transparent rounded-xl overflow-hidden">
      <div class="bg-card/75 flex flex-col h-full p-4 sm:p-6 md:p-8 rounded-xl border-l-4 border-emerald-400">
        <div class="flex items-center gap-2 text-xl font-semibold">
          <h3 class="text-foreground">Fund any issue</h3>
          <span class="text-success drop-shadow-[0_1px_5px_#34d39980]">in seconds</span>
        </div>
        <div class="mt-1 text-sm font-medium text-muted-foreground">
          Help improve the OSS you love and rely on
        </div>
        <.simple_form for={@bounty_form} phx-submit="create_bounty" class="pt-2 space-y-3">
          <div class="grid grid-cols-1 sm:grid-cols-[3fr,1fr] gap-3">
            <.input field={@bounty_form[:url]} placeholder="https://github.com/owner/repo/issues/123" />
            <.input icon="tabler-currency-dollar" field={@bounty_form[:amount]} />
          </div>
          <div class="flex items-center justify-between gap-4">
            <p class="text-xs text-muted-foreground">
              <.icon name="tabler-sparkles" class="size-4 text-current mr-1" /> ...or just comment
              <code class="px-1 py-0.5 text-success">/bounty $100</code>
              on GitHub issues (requires GitHub auth)
            </p>
            <.button size="sm">Submit</.button>
          </div>
        </.simple_form>
      </div>
    </div>
    """
  end

  defp create_tip(assigns) do
    ~H"""
    <div class="border ring-1 ring-transparent rounded-xl overflow-hidden">
      <div class="bg-card/75 flex flex-col h-full p-4 sm:p-6 md:p-8 rounded-xl border-l-4 border-emerald-400">
        <div class="flex items-center gap-2 text-xl font-semibold">
          <h3 class="text-foreground">Tip any developer</h3>
          <span class="text-success drop-shadow-[0_1px_5px_#34d39980]">instantly</span>
        </div>
        <div class="mt-1 text-sm font-medium text-muted-foreground">
          Thank OSS maintainers and contributors on GitHub
        </div>
        <.simple_form for={@tip_form} phx-submit="create_tip" class="pt-2 space-y-3">
          <div class="grid grid-cols-1 sm:grid-cols-[2fr,1fr,1fr] gap-3">
            <.input field={@tip_form[:url]} placeholder="https://github.com/owner/repo/pull/123" />
            <.input field={@tip_form[:github_handle]} placeholder="jsmith" />
            <.input icon="tabler-currency-dollar" field={@tip_form[:amount]} />
          </div>
          <div class="flex items-center justify-between gap-4">
            <p class="text-xs text-muted-foreground">
              <.icon name="tabler-sparkles" class="size-4 text-current mr-1" /> ...or just comment
              <code class="px-1 py-0.5 text-success">/tip $100</code>
              on GitHub issues (requires GitHub auth)
            </p>
            <.button size="sm">Submit</.button>
          </div>
        </.simple_form>
      </div>
    </div>
    """
  end

  defp getting_started(assigns) do
    ~H"""
    <div class={assigns[:class]}>
      <h2 class="text-xl font-semibold leading-none tracking-tight">
        <%= if @previewed_user != @current_org and incomplete?(@achievements, :complete_signin_status) do %>
          Get back in
        <% else %>
          Getting started
        <% end %>
      </h2>
      <nav class="pt-6">
        <ol role="list" class="space-y-6">
          <%= for achievement <- @achievements do %>
            <li class="space-y-6">
              <.achievement achievement={achievement} />
              <.achievement_todo
                id={@id}
                achievement={achievement}
                current_user={@current_user}
                current_org={@current_org}
                secret={@secret}
                login_form={@login_form}
              />
            </li>
          <% end %>
        </ol>
      </nav>
    </div>
    """
  end

  defp sidebar(assigns) do
    ~H"""
    <aside class="scrollbar-thin fixed top-16 right-0 bottom-0 hidden w-96 h-full overflow-y-auto border-l border-border bg-background p-4 pt-6 sm:p-6 md:p-8 lg:flex lg:flex-col">
      <.getting_started
        :if={length(@achievements) > 1}
        id="getting_started_sidebar"
        class="pb-12"
        achievements={
          if incomplete?(@achievements, :complete_signin_status) or
               incomplete?(@achievements, :complete_signup_status),
             do: @achievements |> Enum.take(1),
             else: @achievements
        }
        current_user={@current_user}
        current_org={@current_org}
        secret={@secret}
        login_form={@login_form}
        previewed_user={@previewed_user}
      />
      <%= if @current_org.handle do %>
        <div :if={not incomplete?(@achievements, :create_bounty_status)}>
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-semibold leading-none tracking-tight">Share your bounty board</h2>
          </div>
          <.badge
            id="og-url"
            phx-hook="CopyToClipboard"
            data-value={url(~p"/#{@current_org.handle}/home")}
            phx-click={
              %JS{}
              |> JS.hide(
                to: "#og-url-copy-icon",
                transition: {"transition-opacity", "opacity-100", "opacity-0"}
              )
              |> JS.show(
                to: "#og-url-check-icon",
                transition: {"transition-opacity", "opacity-0", "opacity-100"}
              )
            }
            class="relative cursor-pointer mt-3 text-foreground/90 hover:text-foreground"
            variant="outline"
          >
            <.icon
              id="og-url-copy-icon"
              name="tabler-copy"
              class="absolute left-1 my-auto size-4 mr-2"
            />
            <.icon
              id="og-url-check-icon"
              name="tabler-check"
              class="absolute left-1 my-auto hidden size-4 mr-2"
            />
            <span class="pl-4">
              {AlgoraWeb.Endpoint.host()}{~p"/#{@current_org.handle}/home"}
            </span>
          </.badge>
          <img
            src={~p"/og/#{@current_org.handle}/home"}
            alt={@current_org.name}
            loading="lazy"
            class="mt-3 w-full aspect-[1200/630] rounded-lg ring-1 ring-input bg-black"
          />
        </div>
      <% end %>
      <div class="pb-16 mt-auto -mr-12 grid grid-cols-1 lg:grid-cols-2 gap-y-4 gap-x-6 text-sm whitespace-nowrap">
        <div class="-ml-3 flex items-center gap-2">
          <div class="flex -space-x-2 shrink-0">
            <img
              src="https://github.com/ioannisflo.png"
              alt="Ioannis Florokapis"
              class="relative z-10 inline-block size-6 rounded-full ring-2 ring-background"
            />
            <img
              src="https://github.com/zcesur.png"
              alt="Zafer Cesur"
              class="relative z-0 inline-block size-6 rounded-full ring-2 ring-background"
            />
          </div>
          <button phx-click="start_chat" class="hover:underline">
            Chat with founders
          </button>
        </div>
        <.link
          href={Constants.get(:twitter_url)}
          rel="noopener"
          target="_blank"
          class="flex items-center gap-2"
        >
          <.icon name="tabler-brand-x" class="size-6 text-muted-foreground" />
          @{Constants.get(:twitter_handle)}
        </.link>
        <.link href={"tel:" <> Constants.get(:tel)} class="flex items-center gap-2">
          <.icon name="tabler-phone" class="size-6 text-muted-foreground" />
          {Constants.get(:tel_formatted)}
        </.link>
        <.link href={"mailto:" <> Constants.get(:support_email)} class="flex items-center gap-2">
          <.icon name="tabler-mail" class="size-6 text-muted-foreground" />
          {Constants.get(:support_email)}
        </.link>
      </div>

      <%= if @show_chat do %>
        <div class="fixed bottom-0 right-96 w-[400px] h-[500px] flex flex-col border border-border bg-background rounded-t-lg shadow-lg">
          <div class="flex flex-none items-center justify-between border-b border-border bg-card/50 p-4 backdrop-blur supports-[backdrop-filter]:bg-background/60">
            <div class="flex items-center gap-3">
              <div class="flex -space-x-2">
                <.avatar class="relative z-10 h-8 w-8 ring-2 ring-background">
                  <.avatar_image src="https://github.com/ioannisflo.png" alt="Ioannis Florokapis" />
                </.avatar>
                <.avatar class="relative z-0 h-8 w-8 ring-2 ring-background">
                  <.avatar_image src="https://github.com/zcesur.png" alt="Zafer Cesur" />
                </.avatar>
              </div>
              <div>
                <h2 class="text-lg font-semibold">Algora Founders</h2>
                <p class="text-xs text-muted-foreground">
                  Active {Algora.Util.time_ago(@admins_last_active)}
                </p>
              </div>
            </div>
            <.button variant="ghost" size="icon" phx-click="close_chat">
              <.icon name="tabler-x" class="h-4 w-4" />
            </.button>
          </div>

          <.scroll_area
            class="flex h-full flex-1 flex-col-reverse gap-6 p-4"
            id="messages-container"
            phx-hook="ScrollToBottom"
          >
            <div class="space-y-6">
              <%= for {date, messages} <- @messages
                  |> Enum.group_by(fn msg ->
                    case Date.diff(Date.utc_today(), DateTime.to_date(msg.inserted_at)) do
                      0 -> "Today"
                      1 -> "Yesterday"
                      n when n <= 7 -> Calendar.strftime(msg.inserted_at, "%A")
                      _ -> Calendar.strftime(msg.inserted_at, "%b %d")
                    end
                  end)
                  |> Enum.sort_by(fn {_, msgs} -> hd(msgs).inserted_at end, Date) do %>
                <div class="flex items-center justify-center">
                  <div class="rounded-full bg-background px-2 py-1 text-xs text-muted-foreground">
                    {date}
                  </div>
                </div>

                <div class="flex flex-col gap-6">
                  <%= for message <- Enum.sort_by(messages, & &1.inserted_at, Date) do %>
                    <div class="group flex gap-3">
                      <.avatar class="h-8 w-8">
                        <.avatar_image src={message.sender.avatar_url} />
                        <.avatar_fallback>
                          {Algora.Util.initials(message.sender.name)}
                        </.avatar_fallback>
                      </.avatar>
                      <div class="max-w-[80%] relative rounded-2xl rounded-tl-none bg-muted p-3">
                        {message.content}
                        <div class="text-[10px] mt-1 text-muted-foreground">
                          {message.inserted_at
                          |> DateTime.to_time()
                          |> Time.to_string()
                          |> String.slice(0..4)}
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </.scroll_area>

          <div class="mt-auto flex-none border-t border-border bg-card/50 p-4 backdrop-blur supports-[backdrop-filter]:bg-background/60">
            <form phx-submit="send_message" class="flex items-center gap-2">
              <div class="relative flex-1">
                <.input
                  id="message-input"
                  type="text"
                  name="message"
                  value=""
                  placeholder="Type a message..."
                  autocomplete="off"
                  class="flex-1 pr-24"
                  phx-hook="ClearInput"
                />
                <div class="absolute top-1/2 right-2 flex -translate-y-1/2 gap-1">
                  <.button
                    type="button"
                    variant="ghost"
                    size="icon-sm"
                    phx-hook="EmojiPicker"
                    id="emoji-trigger"
                  >
                    <.icon name="tabler-mood-smile" class="h-4 w-4" />
                  </.button>
                </div>
              </div>
              <.button type="submit" size="icon">
                <.icon name="tabler-send" class="h-4 w-4" />
              </.button>
            </form>
            <div id="emoji-picker-container" class="bottom-[80px] absolute right-4 hidden">
              <emoji-picker></emoji-picker>
            </div>
          </div>
        </div>
      <% end %>
    </aside>
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
        <div>
          Share a bounty opportunity with {@selected_developer.name}. They will be notified and can choose to work on it.
        </div>
        <div class="mt-2 flex items-center gap-1">
          <.icon name="tabler-bulb" class="h-5 w-5 shrink-0" />
          <span>
            New feature, integration, bug fix, CLI, mobile app, MCP, video
          </span>
        </div>
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
                <Logos.github class="h-4 w-4" />
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
          <%= if @live_action == :preview or incomplete?(@achievements, :connect_github_status) do %>
            <div class="relative">
              <div class="absolute inset-0 z-10 bg-background/50" />
              <div class="pointer-events-none">
                <.share_drawer_content
                  :if={@selected_developer}
                  selected_developer={@selected_developer}
                  share_drawer_type={@share_drawer_type}
                  bounty_form={@bounty_form}
                  tip_form={@tip_form}
                  contract_form={@contract_form}
                />
              </div>
              <.alert
                variant="default"
                class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-20 w-auto flex flex-col items-center justify-center gap-2 text-center"
              >
                <.alert_title>Connect GitHub</.alert_title>
                <.alert_description>
                  Connect your GitHub account to create a {@share_drawer_type}.
                </.alert_description>
                <.button phx-click="close_share_drawer" type="button" variant="subtle">
                  Go back
                </.button>
              </.alert>
            </div>
          <% else %>
            <.share_drawer_content
              :if={@selected_developer}
              selected_developer={@selected_developer}
              share_drawer_type={@share_drawer_type}
              bounty_form={@bounty_form}
              tip_form={@tip_form}
              contract_form={@contract_form}
            />
          <% end %>
        </div>
      </.drawer_content>
    </.drawer>
    """
  end

  defp header_prefix(user) do
    case user.type do
      :organization -> user.name
      _ -> "Your"
    end
  end


end
