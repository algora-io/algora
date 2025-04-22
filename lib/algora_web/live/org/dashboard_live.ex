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
  def mount(_params, _session, socket) do
    %{current_org: current_org} = socket.assigns

    if Member.can_create_bounty?(socket.assigns.current_user_role) do
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Algora.PubSub, "auth:#{socket.id}")
      end

      previewed_user = get_previewed_user(current_org)

      _experts = Accounts.list_developers(org_id: current_org.id, earnings_gt: Money.zero(:USD))
      experts = []

      installations = Workspace.list_installations_by(connected_user_id: previewed_user.id, provider: "github")

      contributors = list_contributors(current_org)

      matches = Algora.Settings.get_org_matches(previewed_user)

      admins_last_active = Algora.Admin.admins_last_active()

      developers =
        contributors
        |> Enum.map(& &1.user)
        |> Enum.concat(experts)
        |> Enum.concat(Enum.map(matches, & &1.user))

      {:ok,
       socket
       |> assign(:ip_address, AlgoraWeb.Util.get_ip(socket))
       |> assign(:admins_last_active, admins_last_active)
       |> assign(:has_fresh_token?, Accounts.has_fresh_token?(socket.assigns.current_user))
       |> assign(:installations, installations)
       |> assign(:experts, experts)
       |> assign(:contributors, contributors)
       |> assign(:previewed_user, previewed_user)
       |> assign(:matches, matches)
       |> assign(:developers, developers)
       |> assign(:has_more_bounties, false)
       |> assign(:oauth_url, Github.authorize_url(%{socket_id: socket.id}))
       |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
       |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
       |> assign(:contract_form, to_form(ContractForm.changeset(%ContractForm{}, %{})))
       |> assign(:show_share_drawer, false)
       |> assign(:share_drawer_type, nil)
       |> assign(:selected_developer, nil)
       |> assign(:secret, nil)
       |> assign_login_form(User.login_changeset(%User{}, %{}))
       |> assign_payable_bounties()
       |> assign_contracts()
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
    current_org = socket.assigns.current_org

    stats = Bounties.fetch_stats(org_id: current_org.id, current_user: socket.assigns[:current_user])

    bounties =
      Bounties.list_bounties(
        owner_id: current_org.id,
        limit: page_size(),
        status: :open,
        current_user: socket.assigns[:current_user]
      )

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
     |> assign(:bounty_rows, to_bounty_rows(bounties))
     |> assign(:has_more_bounties, length(bounties) >= page_size())
     |> assign(:stats, stats)}
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
    <div class="lg:pr-96">
      <div class="container mx-auto max-w-7xl space-y-8 lg:space-y-16 p-4 sm:p-6 lg:p-8">
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

        <.section
          :if={@matches != []}
          title="Algora Matches"
          subtitle="Top 1% Algora developers in your tech stack available to hire now"
        >
          <div class="relative w-full flex flex-col gap-4">
            <%= for match <- @matches do %>
              <.match_card
                match={match}
                contract_for_user={contract_for_user(@contracts, match.user)}
                current_org={@current_org}
              />
            <% end %>
          </div>
        </.section>

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

        <.extras :if={is_nil(@current_context.handle)} />
      </div>
    </div>
    <.sidebar
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
  def handle_info({:authenticated, user}, socket) do
    socket =
      socket
      |> assign(:current_user, user)
      |> assign(:has_fresh_token?, true)

    case socket.assigns.pending_action do
      {event, params} ->
        socket = assign(socket, :pending_action, nil)
        handle_event(event, params, socket)

      nil ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%Chat.MessageCreated{message: message}, socket) do
    if message.id in Enum.map(socket.assigns.messages, & &1.id) do
      {:noreply, socket}
    else
      {:noreply, Phoenix.Component.update(socket, :messages, &(&1 ++ [message]))}
    end
  end

  @impl true
  def handle_event("install_app" = event, unsigned_params, socket) do
    {:noreply,
     if socket.assigns.has_fresh_token? do
       redirect(socket, external: Github.install_url_select_target())
     else
       socket
       |> assign(:pending_action, {event, unsigned_params})
       |> push_event("open_popup", %{url: socket.assigns.oauth_url})
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
       |> assign(:pending_action, {event, unsigned_params})
       |> push_event("open_popup", %{url: socket.assigns.oauth_url})}
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
       |> assign(:pending_action, {event, unsigned_params})
       |> push_event("open_popup", %{url: socket.assigns.oauth_url})}
    end
  end

  @impl true
  def handle_event(
        "share_opportunity",
        %{"user_id" => user_id, "type" => "contract", "marketplace" => marketplace?},
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
         marketplace?: marketplace? == "true",
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
            Algora.Admin.alert(
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

  defp assign_more_bounties(socket) do
    %{bounty_rows: rows, current_org: current_org} = socket.assigns

    last_bounty = List.last(rows)

    cursor = %{
      inserted_at: last_bounty.inserted_at,
      id: last_bounty.id
    }

    more_bounties =
      Bounties.list_bounties(
        owner_id: current_org.id,
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

  defp assign_contracts(socket) do
    contracts =
      Contracts.list_contracts(client_id: socket.assigns.current_org.id, status: {:in, [:draft, :active, :paid]})

    assign(socket, :contracts, contracts)
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
              phx-value-marketplace="false"
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

  defp match_card(assigns) do
    ~H"""
    <div class="relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 xl:gap-4 2xl:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6">
      <div class="xl:basis-[45%] w-full truncate">
        <div class="flex items-center justify-between gap-4">
          <div class="flex items-center gap-4">
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
                <.badge
                  :if={@match.badge_text}
                  variant={@match.badge_variant}
                  size="lg"
                  class="shrink-0 absolute top-0 left-0"
                >
                  {@match.badge_text}
                </.badge>
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
                  <Logos.github class="shrink-0 h-4 w-4" />
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
              <%!-- <div
                :if={@match[:hourly_rate]}
                class="flex flex-wrap items-center gap-x-3 gap-y-1 text-sm text-muted-foreground sm:text-sm"
              >
                <span class="font-semibold font-display text-base sm:text-lg text-emerald-400">
                  {@match[:hourly_rate]
                  |> Money.mult!(@match.user.hours_per_week || 30)
                  |> Money.mult!(Decimal.new("1.13"))
                  |> Money.to_string!()}/wk
                </span>
              </div> --%>
            </div>
          </div>
          <.button
            phx-click="share_opportunity"
            phx-value-user_id={@match.user.id}
            phx-value-type="contract"
            phx-value-marketplace="true"
            variant="none"
            class="group bg-emerald-900/10 text-emerald-300 transition-colors duration-75 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border border-emerald-400/40 hover:border-emerald-400/50 focus:border-emerald-400/50"
          >
            <.icon name="tabler-contract" class="size-4 text-current mr-2 -ml-1" /> Contract
          </.button>
        </div>
        <dl :if={@match[:hourly_rate]} class="pt-4">
          <div class="flex justify-between">
            <dt class="text-foreground">
              Total payment for <span class="font-semibold">{@match.user.hours_per_week || 30}</span>
              hours
              <span class="text-xs text-muted-foreground">
                ({@match.user.name}'s availability)
              </span>
              <div class="text-xs text-muted-foreground">
                (includes all platform and payment processing fees)
              </div>
            </dt>
            <dd class="font-display font-semibold tabular-nums text-lg text-emerald-400">
              {Money.to_string!(
                Money.mult!(
                  @match[:hourly_rate] |> Money.mult!(@match.user.hours_per_week || 30),
                  Decimal.new("1.13")
                )
              )}
            </dd>
          </div>
        </dl>
      </div>

      <div class="pt-2 xl:pt-0 xl:pl-4 2xl:pl-8 xl:basis-[55%] xl:border-l xl:border-border">
        <div class="text-sm sm:text-base text-foreground font-medium">
          Completed
          <span class="font-semibold font-display text-emerald-400">
            {@match.user.transactions_count}
            {ngettext(
              "bounty",
              "bounties",
              @match.user.transactions_count
            )}
          </span>
          across
          <span class="font-semibold font-display text-emerald-400">
            {ngettext(
              "%{count} project",
              "%{count} projects",
              @match.user.contributed_projects_count
            )}
          </span>
        </div>
        <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-4 2xl:gap-8">
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
                <div class="text-base font-medium text-muted-foreground">
                  {project.name}
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <.icon name="tabler-star-filled" class="size-4 text-amber-400 mr-1" />{format_number(
                      project.stargazers_count
                    )}
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-foreground font-display font-semibold">
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

  defp contract_for_user(contracts, user) do
    Enum.find(contracts, fn contract -> contract.contractor_id == user.id end)
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

  defp format_number(n) when n >= 1_000_000, do: "#{Float.round(n / 1_000_000, 1)}M"
  defp format_number(n) when n >= 1_000, do: "#{Float.round(n / 1_000, 1)}K"
  defp format_number(n), do: to_string(n)

  defp extras(assigns) do
    ~H"""
    <.section>
      <div class="mx-auto max-w-3xl px-6 lg:px-8 pt-8 xl:pt-0">
        <img
          src={~p"/images/logos/yc.svg"}
          class="h-16 mx-auto"
          alt="Y Combinator Logo"
          loading="lazy"
        />
        <h2 class="mt-4 sm:mt-6 font-display text-xl sm:text-3xl xl:text-4xl font-semibold tracking-tight text-foreground text-center mb-4 !leading-[1.25]">
          YCombinator companies use Algora<br />to build product and hire engineers
        </h2>
        <div class="mx-auto mt-8 max-w-xl gap-12 text-sm leading-6 sm:mt-9">
          <.yc_logo_cloud />
        </div>

        <div class="mx-auto mt-8 gap-8 text-sm leading-6 sm:mt-16">
          <div class="flex flex-col lg:flex-row lg:items-center gap-8">
            <div class="shrink-0 relative flex aspect-square size-[8rem] sm:size-[12rem] items-center justify-center overflow-hidden rounded-2xl bg-gray-800">
              <img
                src={~p"/images/people/tal-borenstein.jpeg"}
                alt="Tal Borenstein"
                class="object-cover"
                loading="lazy"
              />
            </div>
            <div>
              <h3 class="text-xl font-display font-bold leading-[1.2]">
                Keep has 90+ integrations to alert our customers about critical events. Of these,
                <.link
                  href="https://github.com/keephq/keep/issues?q=state%3Aclosed%20label%3A%22%F0%9F%92%8E%20Bounty%22%20%20label%3A%22%F0%9F%92%B0%20Rewarded%22%20label%3AProvider%20"
                  rel="noopener"
                  target="_blank"
                  class="text-success inline-flex items-center hover:text-success-300"
                >
                  42 integrations <.icon name="tabler-external-link" class="size-5 ml-1 mb-4" />
                </.link>
                were built
                using <span class="text-success">bounties on Algora</span>.
              </h3>
              <div class="flex flex-wrap items-center pt-6">
                <div class="flex items-center gap-4">
                  <div>
                    <div class="text-xl font-semibold text-foreground">
                      Tal Borenstein
                    </div>
                    <div class="text-sm font-medium text-muted-foreground">
                      Co-founder & CEO at Keep (YC W23)
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="mx-auto mt-8 gap-8 text-sm leading-6 sm:mt-16">
          <div class="flex flex-col-reverse lg:flex-row lg:items-center gap-8">
            <div>
              <h3 class="text-xl font-display font-bold leading-[1.2]">
                I posted our bounty on <span class="text-success">Upwork</span>
                to try it, overall it's <span class="text-success">1000x more friction</span>
                than OSS bounties with Algora.
              </h3>
              <div class="flex flex-wrap items-center pt-6">
                <div class="flex items-center gap-4">
                  <div>
                    <div class="text-xl font-semibold text-foreground">
                      Louis Beaumont
                    </div>
                    <div class="text-sm font-medium text-muted-foreground">
                      Co-founder & CEO at Screenpipe
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="shrink-0 relative flex aspect-[791/576] w-[12rem] h-auto lg:h-[12rem] lg:w-auto items-center justify-center overflow-hidden rounded-2xl bg-gray-800">
              <img
                src={~p"/images/people/louis-beaumont.png"}
                alt="Louis Beaumont"
                class="object-cover"
                loading="lazy"
              />
            </div>
          </div>
        </div>

        <div class="mx-auto mt-8 gap-8 text-sm leading-6 sm:mt-16">
          <div class="flex flex-col lg:flex-row lg:items-center gap-8">
            <div class="shrink-0 relative flex aspect-square size-[8rem] sm:size-[12rem] items-center justify-center overflow-hidden rounded-2xl bg-gray-800">
              <img
                src={~p"/images/people/john-de-goes.jpg"}
                alt="John A De Goes"
                class="object-cover"
                loading="lazy"
              />
            </div>
            <div>
              <h3 class="text-xl font-display font-bold leading-[1.2]">
                We used Algora extensively at Ziverge to reward over
                <span class="text-success">$70,000</span>
                in bounties and introduce a whole
                <span class="text-success">new generation of contributors</span>
                to the ZIO ecosystem.
              </h3>
              <div class="flex flex-wrap items-center pt-6">
                <div class="flex items-center gap-4">
                  <div>
                    <div class="text-xl font-semibold text-foreground">
                      John A De Goes
                    </div>
                    <div class="text-sm font-medium text-muted-foreground">
                      Founder & CEO at Ziverge
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </.section>
    """
  end

  defp yc_logo_cloud(assigns) do
    ~H"""
    <div>
      <div class="mx-auto grid grid-cols-3 lg:grid-cols-3 items-center justify-center gap-x-5 gap-y-4 sm:gap-x-6 sm:gap-y-6">
        <.link
          class="font-bold font-display text-base sm:text-xl whitespace-nowrap flex items-center justify-center"
          navigate={~p"/browser-use"}
        >
          <img
            class="size-4 sm:size-5 mr-2"
            src={~p"/images/wordmarks/browser-use.svg"}
            loading="lazy"
          /> Browser Use
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/outerbase"}>
          <svg viewBox="0 0 123 16" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-[80%]">
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M73.862 4.6368C74.3447 4.1028 75.3921 3.2509 77.1721 3.2509C79.7667 3.2509 81.7277 5.8024 81.7321 9.1846C81.7321 13.5714 79.7063 15.9195 76.5946 15.9195C74.6451 15.9195 73.915 14.6081 73.8687 14.5248C73.8674 14.5225 73.8664 14.5208 73.8664 14.5208H73.5431C73.1207 15.2456 72.3277 15.733 71.4183 15.733L68.4617 15.7288C68.3323 15.7288 68.2246 15.6228 68.2246 15.4957V15.0082C68.2246 14.9362 68.2548 14.8684 68.3109 14.826L68.8108 14.4276C69.3581 13.991 69.677 13.3341 69.677 12.6432L69.6814 3.0856C69.6814 2.3905 69.3624 1.7335 68.8108 1.297L68.4143 0.9833C68.2936 0.8858 68.2246 0.7417 68.2246 0.5891V0.5044C68.2246 0.2246 68.453 0 68.7375 0H71.8666C72.9656 0.0042 73.862 0.8816 73.862 1.9666V4.6368ZM75.3706 13.9232C76.1205 13.9232 76.6722 13.3341 77.0084 12.1685C77.323 11.0792 77.3574 9.795 77.3532 9.2906C77.3532 6.5695 76.6463 5.1327 75.3016 5.1327C74.5861 5.1327 73.8577 5.9168 73.8577 6.6882L73.8922 12.2702C73.8922 13.3425 74.6551 13.9232 75.3706 13.9232Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M8.03335 0.2C3.60316 0.2 0 3.74183 0 8.09995C0 12.454 3.60316 16 8.03335 16C12.4635 16 16.0667 12.4582 16.0667 8.09995C16.0667 3.74183 12.4635 0.2 8.03335 0.2ZM11.0196 13.5382L10.9793 13.5892C10.5591 14.0952 10.045 14.261 9.68735 14.3077C9.59348 14.3205 9.49961 14.3248 9.4013 14.3248C8.42674 14.3248 7.44325 13.6742 6.5581 12.4369C5.83837 11.4292 5.21251 10.0856 4.79676 8.6527C4.05914 6.0973 4.14408 3.76731 5.01134 2.71287C5.43156 2.20686 5.94566 2.04104 6.30329 1.99429C7.31807 1.85816 8.35521 2.44071 9.294 3.67372C10.0718 4.69425 10.7424 6.10161 11.1895 7.64501C11.9181 10.1622 11.8466 12.4667 11.0196 13.5382Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M42.4345 13.3935C42.1543 13.4825 41.8267 13.5292 41.469 13.5292C40.176 13.5292 39.4046 12.6476 39.4046 11.1726C39.4046 10.5101 39.4126 8.05114 39.4177 6.50448L39.4178 6.4819C39.4201 5.78395 39.4218 5.27668 39.4218 5.2134V4.9591C39.4218 4.9549 39.426 4.9548 39.426 4.9548H41.7406C42.0465 4.9548 42.2922 4.7133 42.2922 4.4123V4.0945C42.2922 3.7935 42.0465 3.5519 41.7406 3.5519H39.4088C39.4046 3.5519 39.4046 3.5477 39.4046 3.5477V1.1276C39.4046 0.775796 39.1158 0.491797 38.758 0.491797H38.4994C38.2495 0.491797 38.0125 0.606196 37.8658 0.805397C37.3831 1.4582 36.06 2.9501 33.7455 3.4587C33.53 3.5307 33.3835 3.7342 33.3835 3.9588V4.3742C33.3835 4.6709 33.6292 4.9125 33.9309 4.9125H35.198C35.2023 4.9125 35.2023 4.9167 35.2023 4.9167V11.961C35.2023 12.9061 35.4825 15.9832 39.1029 15.9832C41.0768 15.9832 42.3741 14.5506 42.8439 13.9361C42.9257 13.8259 42.9387 13.6775 42.8697 13.5546C42.7836 13.4105 42.6026 13.3427 42.4345 13.3935Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M43.4471 9.63387C43.4471 6.13297 46.2399 3.28477 49.6707 3.28477C52.9677 3.28477 55.3598 5.95497 55.3555 9.62967C55.3555 9.71447 55.3555 9.80347 55.3512 9.88817C55.3468 10.0323 55.2218 10.1468 55.071 10.1468H47.8475L47.9596 10.4859C48.6017 12.4355 49.9336 13.3807 52.0368 13.3807C53.3384 13.3807 54.1357 13.1476 54.5581 12.9611C54.6659 12.9145 54.7866 12.9441 54.8641 13.0289L54.8685 13.0332C54.9503 13.1306 54.9547 13.2663 54.8771 13.3637C54.4116 13.9741 52.6446 15.9831 49.6707 15.9831C46.2399 15.9831 43.4471 13.1349 43.4471 9.63387ZM48.507 4.67497C47.6018 4.82327 47.2356 6.46357 47.5847 8.76927H51.3688C50.774 6.59917 49.6016 4.49697 48.507 4.67497Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M105.626 8.70137L105.621 8.69968C104.213 8.1536 102.88 7.63637 102.88 6.47197C102.88 5.60736 103.501 5.02666 104.428 5.02666C105.751 5.02666 106.307 6.15407 106.484 6.63727C106.518 6.73477 106.621 6.80256 106.733 6.80687C106.837 6.80687 107.466 6.80686 108.013 6.81106C108.483 6.81106 108.862 6.43386 108.858 5.97606L108.845 4.36976C108.841 3.91626 108.466 3.54746 108.005 3.54746H107.72C107.358 3.54746 107.018 3.71706 106.806 4.00946L106.471 4.47147C106.471 4.47147 105.548 3.29316 103.174 3.29316C100.527 3.29316 98.2902 5.04786 98.2902 7.12896C98.2902 9.97589 100.72 10.7794 102.68 11.4272L102.691 11.431C103.945 11.8421 105.023 12.1981 105.023 13.0458C105.023 13.4654 104.772 13.9655 103.583 13.9655C102.109 13.9655 100.876 12.7279 100.54 12.1642C100.493 12.0837 100.402 12.0328 100.307 12.0328L99.2168 12.0371C98.7944 12.0371 98.454 12.3761 98.454 12.7915V14.9997C98.454 15.4151 98.7944 15.7499 99.2168 15.7542H99.5271C99.8202 15.7542 100.096 15.6312 100.286 15.4151L100.88 14.7369C100.88 14.7369 102.075 15.9957 104.531 15.9957C107.501 15.9957 109.651 14.6267 109.651 12.7406C109.651 10.2654 107.514 9.43466 105.626 8.70137Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M25.3246 3.54336H31.2853C31.5999 3.54336 31.8585 3.79346 31.8542 4.10286C31.8542 4.27236 31.7766 4.43346 31.643 4.53946L31.3888 4.74286C30.7638 5.23876 30.3974 5.98896 30.3974 6.78156V12.4823C30.3974 13.2748 30.7638 14.025 31.3931 14.5252L31.643 14.7244C31.7766 14.8303 31.8542 14.9914 31.8542 15.1609C31.8542 15.4746 31.5956 15.7246 31.281 15.7246H28.514C27.5917 15.7246 26.803 15.1948 26.4323 14.4319L26.1522 14.4362C26.1522 14.4362 24.7471 15.9874 22.5533 15.9874C19.9501 15.9874 18.3037 14.2412 18.3037 11.4354V6.56966C18.2865 5.89576 17.9718 5.26416 17.4374 4.84036L17.0624 4.54366C16.9288 4.43766 16.8512 4.27666 16.8512 4.10706C16.8512 3.79346 17.1098 3.54336 17.4245 3.54336H20.7345C21.7042 3.54336 22.493 4.31906 22.493 5.27266V11.5117C22.493 11.5133 22.4928 11.5149 22.4926 11.5165C22.4923 11.5184 22.4919 11.5202 22.4914 11.522L22.4908 11.5243C22.4897 11.5285 22.4886 11.5328 22.4886 11.5371C22.4973 12.9993 23.2472 13.9445 24.3979 13.9445C25.4841 13.9445 26.1521 12.9866 26.2082 12.9019V6.78576C26.2082 5.99316 25.8418 5.23876 25.2126 4.74286L24.9626 4.54366C24.829 4.43766 24.7514 4.27666 24.7514 4.10706C24.7514 3.79346 25.01 3.54336 25.3246 3.54336Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M65.4149 3.25098C63.9496 3.25098 62.885 4.23428 62.2816 5.45488L61.9928 5.45918L61.9885 5.45488C61.8118 4.37408 60.8635 3.54758 59.7128 3.54758H56.9458C56.6312 3.54758 56.3726 3.79768 56.3726 4.11138C56.3726 4.28088 56.4502 4.44198 56.5838 4.54788L56.9587 4.84458C57.5105 5.28118 57.8294 5.93808 57.8294 6.63318V12.6475C57.8294 13.3384 57.5105 13.9953 56.9631 14.4319L56.5838 14.7328C56.4502 14.8388 56.3726 14.9998 56.3726 15.1694C56.3726 15.4788 56.6269 15.7331 56.9458 15.7331H62.9066C63.2212 15.7331 63.4798 15.483 63.4798 15.1694C63.4798 14.9998 63.4022 14.8388 63.2686 14.7328L62.8935 14.4361C62.3419 13.9996 62.023 13.3426 62.023 12.6475V7.05278C62.023 6.71798 62.3074 6.25598 62.704 6.25598C62.9887 6.25598 63.1994 6.52205 63.4552 6.84495C63.8498 7.34321 64.3516 7.97678 65.3977 7.97678C66.751 7.97678 67.7595 6.93408 67.7595 5.60328C67.7553 4.01388 66.6993 3.25098 65.4149 3.25098Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M117.099 3.28477C113.668 3.28477 110.875 6.13297 110.875 9.63387C110.875 13.1349 113.668 15.9831 117.099 15.9831C120.072 15.9831 121.84 13.9741 122.305 13.3637C122.383 13.2663 122.379 13.1306 122.296 13.0332L122.292 13.0289C122.215 12.9441 122.094 12.9145 121.986 12.9611C121.564 13.1476 120.767 13.3807 119.465 13.3807C117.361 13.3807 116.03 12.4355 115.388 10.4859L115.276 10.1468H122.499C122.65 10.1468 122.775 10.0323 122.779 9.88817C122.783 9.80347 122.783 9.71447 122.783 9.62967C122.787 5.95497 120.392 3.28477 117.099 3.28477ZM115.008 8.76927C114.66 6.46357 115.026 4.82327 115.931 4.67497C117.026 4.49697 118.197 6.59917 118.792 8.76927H115.008Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M96.6568 4.54368L96.4068 4.74288C95.7776 5.23878 95.4156 5.98898 95.4156 6.78578V12.6433C95.4156 13.3384 95.7345 13.9911 96.2819 14.4277L96.6611 14.7286C96.7948 14.8345 96.8724 14.9956 96.8724 15.1651C96.8724 15.4788 96.6138 15.7288 96.2991 15.7288L92.8813 15.7458C92.4891 15.7458 92.1356 15.5169 91.9805 15.1609L91.5408 14.1522L91.2133 14.1564C91.2133 14.1564 91.2114 14.1593 91.2088 14.1635C91.1314 14.288 90.0758 15.9874 88.0067 15.9874C85.4078 15.9874 83.451 13.4359 83.451 10.0494C83.451 5.92118 85.5242 3.25098 88.7308 3.25098C90.4763 3.25098 91.5279 4.68778 91.5366 4.70048L91.7176 4.95478L92.1787 4.03928C92.3296 3.73408 92.6054 3.54338 92.9718 3.54338H96.2948C96.6138 3.54338 96.868 3.79768 96.868 4.10708C96.868 4.27668 96.7904 4.43768 96.6568 4.54368ZM87.8214 9.61278C87.8214 12.2449 88.5153 13.6351 89.8255 13.6351C90.4978 13.6351 91.1788 12.9357 91.2262 12.2152V11.27L91.2004 6.73068C91.2004 5.69228 90.4591 5.13278 89.7609 5.13278C89.0281 5.13278 88.4894 5.70498 88.1618 6.83238C87.8559 7.88348 87.8214 9.12538 87.8214 9.61278Z"
              fill="currentColor"
            >
            </path>
          </svg>
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/triggerdotdev"}>
          <img
            src={~p"/images/wordmarks/triggerdotdev.png"}
            alt="Trigger.dev"
            class="col-auto sm:w-[90%] saturate-0"
            loading="lazy"
          />
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/traceloop"}>
          <img
            src={~p"/images/wordmarks/traceloop.png"}
            alt="Traceloop"
            class="sm:w-[80%] col-auto saturate-0"
            loading="lazy"
          />
        </.link>
        <.link
          class="font-bold font-display text-base sm:text-xl whitespace-nowrap flex items-center justify-center"
          navigate={~p"/trieve"}
        >
          <img
            src={~p"/images/wordmarks/trieve.png"}
            alt="Trieve logo"
            class="size-8 sm:size-9 mr-2 brightness-0 invert"
            loading="lazy"
          /> Trieve
        </.link>
        <.link
          class="font-bold font-display text-base sm:text-lg whitespace-nowrap flex items-center justify-center"
          navigate={~p"/twentyhq"}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            xmlns:xlink="http://www.w3.org/1999/xlink"
            viewBox="0 0 40 40"
            class="shrink-0 size-4 sm:size-6 mr-2"
          >
            <path
              fill="currentColor"
              d="M 34.95 0 L 5.05 0 C 2.262 0 0 2.262 0 5.05 L 0 34.95 C 0 37.738 2.262 40 5.05 40 L 34.95 40 C 37.738 40 40 37.738 40 34.95 L 40 5.05 C 40 2.262 37.738 0 34.95 0 Z M 8.021 14.894 C 8.021 12.709 9.794 10.935 11.979 10.935 L 19.6 10.935 C 19.712 10.935 19.815 11.003 19.862 11.106 C 19.909 11.209 19.888 11.329 19.812 11.415 L 18.141 13.229 C 17.85 13.544 17.441 13.726 17.012 13.726 L 12 13.726 C 11.344 13.726 10.812 14.259 10.812 14.915 L 10.812 17.909 C 10.812 18.294 10.5 18.606 10.115 18.606 L 8.721 18.606 C 8.335 18.606 8.024 18.294 8.024 17.909 L 8.024 14.894 Z M 31.729 25.106 C 31.729 27.291 29.956 29.065 27.771 29.065 L 24.532 29.065 C 22.347 29.065 20.574 27.291 20.574 25.106 L 20.574 19.438 C 20.574 19.053 20.718 18.682 20.979 18.397 L 22.868 16.347 C 22.947 16.262 23.071 16.232 23.182 16.274 C 23.291 16.318 23.365 16.421 23.365 16.538 L 23.365 25.088 C 23.365 25.744 23.897 26.276 24.553 26.276 L 27.753 26.276 C 28.409 26.276 28.941 25.744 28.941 25.088 L 28.941 14.915 C 28.941 14.259 28.409 13.726 27.753 13.726 L 24.032 13.726 C 23.606 13.726 23.2 13.906 22.909 14.218 L 11.812 26.276 L 18.479 26.276 C 18.865 26.276 19.176 26.588 19.176 26.974 L 19.176 28.368 C 19.176 28.753 18.865 29.065 18.479 29.065 L 9.494 29.065 C 8.679 29.065 8.018 28.403 8.018 27.588 L 8.018 26.85 C 8.018 26.479 8.156 26.124 8.409 25.85 L 20.85 12.335 C 21.674 11.441 22.829 10.935 24.044 10.935 L 27.768 10.935 C 29.953 10.935 31.726 12.709 31.726 14.894 L 31.726 25.106 Z"
            />
          </svg>
          Twenty
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/aidenybai"}>
          <img
            src={~p"/images/wordmarks/million.png"}
            alt="Million"
            class="col-auto w-[75%] saturate-0"
            loading="lazy"
          />
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/moonrepo"}>
          <img src={~p"/images/wordmarks/moonrepo.svg"} alt="moon" class="w-[70%]" loading="lazy" />
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/dittofeed"}>
          <img
            src={~p"/images/wordmarks/dittofeed.png"}
            alt="Dittofeed"
            class="col-auto w-[75%] brightness-0 invert"
            loading="lazy"
          />
        </.link>

        <.link
          class="relative flex items-center justify-center brightness-0 invert"
          navigate={~p"/onyx-dot-app"}
        >
          <img
            src={~p"/images/wordmarks/onyx.png"}
            alt="Onyx Logo"
            class="object-contain w-[55%]"
            loading="lazy"
          />
        </.link>

        <.link
          class="font-bold font-display text-base sm:text-xl whitespace-nowrap flex items-center justify-center brightness-0 invert"
          aria-label="Logo"
          navigate={~p"/mendableai"}
        >
          🔥
          Firecrawl
        </.link>

        <.link class="relative flex items-center justify-center" navigate={~p"/keephq"}>
          <img
            src={~p"/images/wordmarks/keep.png"}
            alt="Keep"
            class="col-auto w-[70%] sm:w-[50%]"
            loading="lazy"
          />
        </.link>

        <.link
          class="font-bold font-display text-base sm:text-xl whitespace-nowrap flex items-center justify-center"
          navigate={~p"/windmill-labs"}
        >
          <img
            src={~p"/images/wordmarks/windmill.svg"}
            alt="Windmill"
            class="size-4 sm:size-6 mr-2 saturate-0"
            loading="lazy"
          /> Windmill
        </.link>

        <.link class="relative flex items-center justify-center" navigate={~p"/panoratech"}>
          <img
            src={~p"/images/wordmarks/panora.png"}
            alt="Panora"
            class="col-auto w-[60%] sm:w-[45%] saturate-0 brightness-0 invert"
            loading="lazy"
          />
        </.link>

        <.link class="relative flex items-center justify-center" navigate={~p"/highlight"}>
          <img
            src={~p"/images/wordmarks/highlight.png"}
            alt="Highlight"
            class="col-auto sm:w-[80%] saturate-0"
            loading="lazy"
          />
        </.link>
      </div>
    </div>
    """
  end
end
