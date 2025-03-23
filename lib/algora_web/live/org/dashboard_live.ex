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
  alias Algora.Contracts
  alias Algora.Github
  alias Algora.Organizations
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Workspace
  alias Algora.Workspace.Contributor
  alias Algora.Workspace.Ticket
  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.ContractForm
  alias AlgoraWeb.Forms.TipForm
  alias Swoosh.Email

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    %{current_org: current_org} = socket.assigns

    if socket.assigns.current_user_role in [:admin, :mod] do
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Algora.PubSub, "auth:#{socket.id}")
      end

      _experts = Accounts.list_developers(org_id: current_org.id, earnings_gt: Money.zero(:USD))
      experts = []

      installations = Workspace.list_installations_by(connected_user_id: current_org.id, provider: "github")

      contributors =
        case current_org.last_context do
          "repo/" <> repo ->
            case String.split(repo, "/") do
              [repo_owner, repo_name] -> Workspace.list_repository_contributors(repo_owner, repo_name)
              _ -> Workspace.list_contributors(current_org.provider_login)
            end

          _ ->
            Workspace.list_contributors(current_org.provider_login)
        end

      {:ok,
       socket
       |> assign(:has_fresh_token?, Accounts.has_fresh_token?(socket.assigns.current_user))
       |> assign(:installations, installations)
       |> assign(:experts, experts)
       |> assign(:contributors, contributors)
       |> assign(:developers, contributors |> Enum.map(& &1.user) |> Enum.concat(experts))
       |> assign(:has_more_bounties, false)
       |> assign(:oauth_url, Github.authorize_url(%{socket_id: socket.id}))
       |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
       |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
       |> assign(:contract_form, to_form(ContractForm.changeset(%ContractForm{}, %{})))
       |> assign(:show_share_drawer, false)
       |> assign(:share_drawer_type, nil)
       |> assign(:selected_developer, nil)
       |> assign(:secret_code, nil)
       |> assign_login_form(User.login_changeset(%User{}, %{}))
       |> assign_payable_bounties()
       |> assign_contracts()
       |> assign_achievements()}
    else
      {:ok, redirect(socket, to: ~p"/org/#{current_org.handle}/home")}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    current_org = socket.assigns.current_org
    current_status = get_current_status(params)

    stats = Bounties.fetch_stats(current_org.id)

    bounties = Bounties.list_bounties(owner_id: current_org.id, limit: page_size(), status: :open)
    transactions = Payments.list_hosted_transactions(current_org.id, limit: page_size())

    {:noreply,
     socket
     |> assign(:current_status, current_status)
     |> assign(:bounty_rows, to_bounty_rows(bounties))
     |> assign(:transaction_rows, to_transaction_rows(transactions))
     |> assign(:has_more_bounties, length(bounties) >= page_size())
     |> assign(:has_more_transactions, length(transactions) >= page_size())
     |> assign(:stats, stats)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="lg:pr-96">
      <div class="container mx-auto max-w-7xl space-y-8 lg:space-y-16 p-8">
        <.section :if={@payable_bounties != %{}}>
          <.card>
            <.card_header>
              <.card_title>Pending Payments</.card_title>
              <.card_description>
                The following claims have been approved and are ready for payment.
              </.card_description>
            </.card_header>
            <.card_content class="p-0">
              <table class="w-full caption-bottom text-sm">
                <tbody class="[&_tr:last-child]:border-0">
                  <%= for {_group_id, [%{target: %{bounties: [bounty | _]}} | _] = claims} <- @payable_bounties do %>
                    <tr
                      class="bg-white/[2%] from-white/[2%] via-white/[2%] to-white/[2%] border-b border-white/15 bg-gradient-to-br transition-colors data-[state=selected]:bg-gray-100 hover:bg-gray-100/50 dark:data-[state=selected]:bg-gray-800 dark:hover:bg-white/[2%]"
                      data-state="false"
                    >
                      <td colspan={2} class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
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
                    </tr>
                    <tr
                      class="border-b border-white/15 bg-gray-950/50 transition-colors data-[state=selected]:bg-gray-100 hover:bg-gray-100/50 dark:data-[state=selected]:bg-gray-800 dark:hover:bg-gray-950/50"
                      data-state="false"
                    >
                      <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle w-full">
                        <div class="min-w-[250px]">
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
                              <div class="text-sm font-medium text-gray-200">
                                {claims
                                |> Enum.map(fn c -> User.handle(c.user) end)
                                |> Algora.Util.format_name_list()}
                              </div>
                              <div class="text-xs text-gray-400">
                                {Algora.Util.time_ago(hd(claims).inserted_at)}
                              </div>
                            </div>
                          </div>
                        </div>
                      </td>
                      <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
                        <div class="min-w-[180px]">
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
          title={"#{@current_org.name} Contributors"}
          subtitle="Share bounties, tips or contract opportunities with your top contributors"
        >
          <div class="relative w-full overflow-auto max-h-[400px] scrollbar-thin">
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
                <h2 class="text-2xl font-bold dark:text-white">{@current_org.name} Bounties</h2>
                <p class="text-sm dark:text-gray-300">
                  Create new bounties by commenting
                  <code class="mx-1 inline-block rounded bg-emerald-950/75 px-1 py-0.5 font-mono text-sm text-emerald-400 ring-1 ring-emerald-400/25">
                    /bounty $1000
                  </code>
                  on GitHub issues.
                </p>
              </div>
              <div :if={length(@bounty_rows) + length(@transaction_rows) > 0} class="pb-4 md:pb-0">
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
                      aria-selected={@current_status == :open}
                      class={"inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium #{if @current_status == :open, do: "bg-emerald-700 text-white", else: "hover:bg-emerald-700/50"}"}
                      data-state={if @current_status == :open, do: "active", else: "inactive"}
                      phx-click="change-tab"
                      phx-value-tab="open"
                    >
                      <div class="relative flex items-center gap-2.5 text-sm md:text-base">
                        <div class="truncate">Open</div>
                        <span class={"min-w-[1ch] font-mono #{if @current_status == :open, do: "text-emerald-200", else: "text-gray-400 group-hover:text-emerald-200"}"}>
                          {@stats.open_bounties_count}
                        </span>
                      </div>
                    </button>
                    <button
                      type="button"
                      role="tab"
                      aria-selected={@current_status == :paid}
                      class={"inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium #{if @current_status == :paid, do: "bg-emerald-700 text-white", else: "hover:bg-emerald-700/50"}"}
                      data-state={if @current_status == :paid, do: "active", else: "inactive"}
                      phx-click="change-tab"
                      phx-value-tab="completed"
                    >
                      <div class="relative flex items-center gap-2.5 text-sm md:text-base">
                        <div class="truncate">Completed</div>
                        <span class={"min-w-[1ch] font-mono #{if @current_status == :paid, do: "text-emerald-200", else: "text-gray-400 group-hover:text-emerald-200"}"}>
                          {@stats.rewarded_bounties_count}
                        </span>
                      </div>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div :if={@current_status == :open} class="relative">
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
                  id="load-more-indicator"
                >
                  <div class="animate-pulse text-muted-foreground">
                    <.icon name="tabler-loader" class="h-6 w-6 animate-spin" />
                  </div>
                </div>
              </div>
            <% end %>
          </div>
          <div :if={@current_status == :paid} class="relative">
            <%= if Enum.empty?(@bounty_rows) do %>
              <.card class="rounded-lg bg-card py-12 text-center lg:rounded-[2rem]">
                <.card_header>
                  <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                    <.icon name="tabler-diamond" class="h-8 w-8 text-muted-foreground" />
                  </div>
                  <.card_title>No completed bounties yet</.card_title>
                  <.card_description>
                    Completed bounties will appear here once completed
                  </.card_description>
                </.card_header>
              </.card>
            <% else %>
              <%= for %{transaction: transaction, recipient: recipient, ticket: ticket} <- @transaction_rows do %>
                <div class="mb-4 rounded-lg border border-border bg-card p-4">
                  <div class="flex gap-4">
                    <div class="flex-1">
                      <div class="mb-2 font-mono text-2xl font-extrabold text-success">
                        {Money.to_string!(transaction.net_amount)}
                      </div>
                      <div :if={ticket.repository} class="mb-1 text-sm text-muted-foreground">
                        {ticket.repository.user.provider_login}/{ticket.repository.name}#{ticket.number}
                      </div>
                      <div class="font-medium">
                        {ticket.title}
                      </div>
                      <div class="mt-1 text-xs text-muted-foreground">
                        {Algora.Util.time_ago(transaction.succeeded_at)}
                      </div>
                    </div>

                    <div class="flex w-32 flex-col items-center border-l border-border pl-4">
                      <h3 class="mb-3 text-xs font-medium uppercase text-muted-foreground">
                        Awarded to
                      </h3>
                      <img
                        src={recipient.avatar_url}
                        class="mb-2 h-16 w-16 rounded-full"
                        alt={recipient.name}
                      />
                      <div class="text-center text-sm font-medium">
                        {recipient.name}
                        <div>
                          {Algora.Misc.CountryEmojis.get(recipient.country)}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
              <div
                :if={@has_more_transactions}
                class="flex justify-center mt-4"
                id="load-more-indicator"
              >
                <div class="animate-pulse text-gray-400">
                  <.icon name="tabler-loader" class="h-6 w-6 animate-spin" />
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <.section
          title={"#{@current_org.name} Ecosystem"}
          subtitle="Help maintain and grow your ecosystem by creating bounties and tips in your dependencies"
        >
          <div class="grid grid-cols-1 gap-8 md:grid-cols-2">
            {create_bounty(assigns)}
            {create_tip(assigns)}
          </div>
        </.section>
      </div>
    </div>
    {sidebar(assigns)}
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
      changeset =
        %BountyForm{}
        |> BountyForm.changeset(params)
        |> Map.put(:action, :validate)

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
               visibility: :exclusive,
               shared_with:
                 case socket.assigns.selected_developer do
                   %User{handle: nil, provider_id: provider_id} -> [to_string(provider_id)]
                   %User{id: id} -> [id]
                   _ -> raise "Developer not selected"
                 end
             ) do
        {:noreply,
         socket
         |> assign_achievements()
         |> put_flash(:info, "Bounty created")}
      else
        %{valid?: false} ->
          {:noreply, assign(socket, :bounty_form, to_form(changeset))}

        {:error, :already_exists} ->
          {:noreply, put_flash(socket, :warning, "You have already created a bounty for this ticket")}

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
      changeset =
        %TipForm{}
        |> TipForm.changeset(Map.put(params, "github_handle", socket.assigns.current_user.provider_login))
        |> Map.put(:action, :validate)

      ticket_ref = get_field(changeset, :ticket_ref)

      with %{valid?: true} <- changeset,
           {:ok, checkout_url} <-
             Bounties.create_tip(
               %{
                 creator: socket.assigns.current_user,
                 owner: socket.assigns.current_org,
                 recipient: socket.assigns.selected_developer,
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
             |> assign_contracts()
             |> assign_achievements()
             |> put_flash(:info, "Contract offer sent to #{socket.assigns.selected_developer.name}")}

          {:error, changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to create contract: #{inspect(changeset.errors)}")}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, :contract_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("send_login_code", %{"user" => %{"email" => email}}, socket) do
    code = Nanoid.generate()

    changeset = User.login_changeset(%User{}, %{})

    case send_login_code_to_user(email, code) do
      {:ok, _id} ->
        {:noreply,
         socket
         |> assign(:secret_code, code)
         |> assign(:email, email)
         |> assign_login_form(changeset)}

      {:error, reason} ->
        Logger.error("Failed to send login code to #{email}: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "We had trouble sending mail to #{email}. Please try again")}
    end
  end

  @impl true
  def handle_event("send_login_code", %{"user" => %{"login_code" => code}}, socket) do
    if Plug.Crypto.secure_compare(code, socket.assigns.secret_code) do
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

          {:noreply,
           socket
           |> assign(:current_user, user)
           |> assign_achievements()}

        user ->
          token = AlgoraWeb.UserAuth.generate_login_code(user.email)

          {:noreply, redirect(socket, to: AlgoraWeb.UserAuth.login_path(user.email, token))}
      end
    else
      throttle()
      {:noreply, put_flash(socket, :error, "Invalid login code")}
    end
  end

  @impl true
  def handle_event("change-tab", %{"tab" => "completed"}, socket) do
    {:noreply, push_patch(socket, to: ~p"/org/#{socket.assigns.current_org.handle}?status=completed")}
  end

  @impl true
  def handle_event("change-tab", %{"tab" => "open"}, socket) do
    {:noreply, push_patch(socket, to: ~p"/org/#{socket.assigns.current_org.handle}?status=open")}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    {:noreply,
     case socket.assigns.current_status do
       :open -> assign_more_bounties(socket)
       :paid -> assign_more_transactions(socket)
     end}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp throttle, do: :timer.sleep(1000)

  defp assign_login_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :login_form, to_form(changeset))
  end

  defp to_bounty_rows(bounties), do: bounties

  defp to_transaction_rows(transactions), do: transactions

  defp assign_more_bounties(socket) do
    %{rows: rows, current_org: current_org} = socket.assigns

    last_bounty = List.last(rows).bounty

    cursor = %{
      inserted_at: last_bounty.inserted_at,
      id: last_bounty.id
    }

    more_bounties =
      Bounties.list_bounties(
        owner_id: current_org.id,
        limit: page_size(),
        status: socket.assigns.current_status,
        before: cursor
      )

    socket
    |> assign(:bounty_rows, rows ++ to_bounty_rows(more_bounties))
    |> assign(:has_more, length(more_bounties) >= page_size())
  end

  defp assign_more_transactions(socket) do
    %{transaction_rows: rows, current_org: current_org} = socket.assigns

    last_transaction = List.last(rows).transaction

    more_transactions =
      Payments.list_hosted_transactions(
        current_org.id,
        limit: page_size(),
        before: %{
          succeeded_at: last_transaction.succeeded_at,
          id: last_transaction.id
        }
      )

    socket
    |> assign(:transaction_rows, rows ++ to_transaction_rows(more_transactions))
    |> assign(:has_more_transactions, length(more_transactions) >= page_size())
  end

  defp get_current_status(params) do
    case params["status"] do
      "open" -> :open
      "completed" -> :paid
      _ -> :open
    end
  end

  defp page_size, do: 10

  @from_name "Algora"
  @from_email "info@algora.io"

  defp send_login_code_to_user(email, code) do
    email =
      Email.new()
      |> Email.to(email)
      |> Email.from({@from_name, @from_email})
      |> Email.subject("Login code for Algora")
      |> Email.text_body("""
      Here is your login code for Algora!

       #{code}

      If you didn't request this link, you can safely ignore this email.

      --------------------------------------------------------------------------------

      For correspondence, please email the Algora founders at ioannis@algora.io and zafer@algora.io

      © 2025 Algora PBC.
      """)

    Algora.Mailer.deliver(email)
  end

  defp assign_payable_bounties(socket) do
    org = socket.assigns.current_org

    payable_claims =
      Repo.all(
        from c in Claim,
          where: c.status == :approved,
          join: t in assoc(c, :target),
          join: b in assoc(t, :bounties),
          where: b.owner_id == ^org.id,
          left_join: tx in Transaction,
          on: tx.claim_id == c.id and tx.type == :debit,
          where: is_nil(tx.status) or tx.status not in [:initialized, :succeeded],
          join: r in assoc(t, :repository),
          join: ru in assoc(r, :user),
          join: cu in assoc(c, :user),
          left_join: s in assoc(c, :source),
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
    <.simple_form
      :if={!@secret_code}
      for={@login_form}
      id="send_login_code_form"
      phx-submit="send_login_code"
    >
      <.input
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
    <.simple_form
      :if={@secret_code}
      for={@login_form}
      id="send_login_code_form"
      phx-submit="send_login_code"
    >
      <.input field={@login_form[:login_code]} type="text" label="Login code" required />
      <.button phx-disable-with="Signing in..." class="w-full py-5">
        Submit
      </.button>
    </.simple_form>
    """
  end

  defp achievement_todo(%{achievement: %{id: :connect_github_status}} = assigns) do
    ~H"""
    <.button :if={!@current_user.provider_login} href={Github.authorize_url()} class="ml-auto gap-2">
      <Logos.github class="w-4 h-4 mr-2 -ml-1" /> Connect GitHub
    </.button>
    """
  end

  defp achievement_todo(%{achievement: %{id: :install_app_status}} = assigns) do
    ~H"""
    <.button phx-click="install_app" class="ml-auto gap-2">
      <Logos.github class="w-4 h-4 mr-2 -ml-1" /> Install GitHub App
    </.button>
    """
  end

  defp achievement_todo(assigns) do
    ~H"""
    """
  end

  defp assign_achievements(socket) do
    current_org = socket.assigns.current_org

    status_fns = [
      {&personalize_status/1, "Personalize Algora", nil},
      {&complete_signup_status/1, "Complete signup", nil},
      {&connect_github_status/1, "Connect GitHub", nil},
      {&install_app_status/1, "Install Algora in #{current_org.name}", nil},
      {&create_bounty_status/1, "Create a bounty", nil},
      {&reward_bounty_status/1, "Reward a bounty", nil},
      {&create_contract_status/1, "Create a contract", nil},
      {&reward_contract_status/1, "Reward a contract", nil},
      {&share_with_friend_status/1, "Share Algora with a friend", nil}
    ]

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
    case Bounties.list_bounties(owner_id: socket.assigns.current_org.id, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp reward_bounty_status(socket) do
    case Bounties.list_bounties(owner_id: socket.assigns.current_org.id, status: :paid, limit: 1) do
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

  defp reward_contract_status(socket) do
    case Enum.filter(socket.assigns.contracts, &(&1.status == :paid)) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp share_with_friend_status(_socket), do: :upcoming

  defp developer_card(assigns) do
    ~H"""
    <tr class="border-b transition-colors">
      <td class="py-4 align-middle">
        <div class="flex items-center justify-between gap-4">
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
                class="pt-0.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm"
              >
                <.link
                  :if={@user.provider_login}
                  href={"https://github.com/#{@user.provider_login}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <Logos.github class="h-4 w-4" />
                  <span class="whitespace-nowrap">{@user.provider_login}</span>
                </.link>
                <.link
                  :if={@user.provider_meta["twitter_handle"]}
                  href={"https://x.com/#{@user.provider_meta["twitter_handle"]}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <.icon name="tabler-brand-x" class="h-4 w-4" />
                  <span class="whitespace-nowrap">{@user.provider_meta["twitter_handle"]}</span>
                </.link>
                <div :if={@user.provider_meta["location"]} class="flex items-center gap-1">
                  <.icon name="tabler-map-pin" class="h-4 w-4" />
                  <span class="whitespace-nowrap">{@user.provider_meta["location"]}</span>
                </div>
                <div :if={@user.provider_meta["company"]} class="flex items-center gap-1">
                  <.icon name="tabler-building" class="h-4 w-4" />
                  <span class="whitespace-nowrap">
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
              class="group bg-card text-foreground transition-colors duration-75 hover:bg-blue-800/10 hover:text-blue-400 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border border-white/50 hover:border-blue-400/50 focus:border-blue-400/50"
            >
              <.icon name="tabler-diamond" class="size-4 text-current mr-2 -ml-1" /> Bounty
            </.button>
            <.button
              phx-click="share_opportunity"
              phx-value-user_id={@user.id}
              phx-value-type="tip"
              variant="none"
              class="group bg-card text-foreground transition-colors duration-75 hover:bg-red-800/10 hover:text-red-400 hover:drop-shadow-[0_1px_5px_#f8717180] focus:bg-red-800/10 focus:text-red-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#f8717180] border border-white/50 hover:border-red-400/50 focus:border-red-400/50"
            >
              <.icon name="tabler-heart" class="size-4 text-current mr-2 -ml-1" /> Tip
            </.button>

            <.button
              :if={@contract_for_user && @contract_for_user.status == :active}
              navigate={~p"/org/#{@current_org.handle}/contracts/#{@contract_for_user.id}"}
              variant="none"
              class="bg-emerald-800/10 text-emerald-400 drop-shadow-[0_1px_5px_#34d39980] focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border border-emerald-400/50 focus:border-emerald-400/50"
            >
              <.icon name="tabler-contract" class="size-4 text-current mr-2 -ml-1" /> Contract
            </.button>
            <.button
              :if={@contract_for_user && @contract_for_user.status in [:draft, :paid]}
              navigate={~p"/org/#{@current_org.handle}/contracts/#{@contract_for_user.id}"}
              variant="none"
              class="bg-gray-800/10 text-gray-400 drop-shadow-[0_1px_5px_#f8717180] focus:bg-gray-800/10 focus:text-gray-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#f8717180] border border-gray-400/50 focus:border-gray-400/50"
            >
              <.icon name="tabler-clock" class="size-4 text-current mr-2 -ml-1" /> Contract
            </.button>
            <.button
              :if={!@contract_for_user}
              phx-click="share_opportunity"
              phx-value-user_id={@user.id}
              phx-value-type="contract"
              variant="none"
              class="group bg-card text-foreground transition-colors duration-75 hover:bg-emerald-800/10 hover:text-emerald-400 hover:drop-shadow-[0_1px_5px_#34d39980] focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border border-white/50 hover:border-emerald-400/50 focus:border-emerald-400/50"
            >
              <.icon name="tabler-contract" class="size-4 text-current mr-2 -ml-1" /> Contract
            </.button>
            <.dropdown_menu>
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
            </.dropdown_menu>
          </div>
        </div>
      </td>
    </tr>
    """
  end

  defp contract_for_user(contracts, user) do
    Enum.find(contracts, fn contract -> contract.contractor_id == user.id end)
  end

  defp create_bounty(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <div class="text-3xl font-semibold text-foreground">
          Fund any issue
          <span class="text-success drop-shadow-[0_1px_5px_#34d39980]">
            in seconds
          </span>
        </div>
        <div class="text-base font-medium text-muted-foreground">
          Help improve the OSS you love and rely on
        </div>
      </.card_header>
      <.card_content>
        <.simple_form for={@bounty_form} phx-submit="create_bounty">
          <div class="flex flex-col gap-6">
            <.input
              label="Issue URL"
              field={@bounty_form[:url]}
              placeholder="https://github.com/swift-lang/swift/issues/1337"
            />
            <.input label="Amount" icon="tabler-currency-dollar" field={@bounty_form[:amount]} />
            <p class="text-sm text-muted-foreground">
              <.icon name="tabler-sparkles" class="size-4 text-current mr-1" /> Comment
              <code class="px-1 py-0.5 text-success">/bounty $100</code>
              on GitHub issues
              <button
                :if={@installations == []}
                type="button"
                phx-click="install_app"
                class="hover:underline"
              >
                (requires the Algora app)
              </button>
            </p>
            <div class="flex justify-end gap-4">
              <.button>Submit</.button>
            </div>
          </div>
        </.simple_form>
      </.card_content>
    </.card>
    """
  end

  defp create_tip(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <div class="text-3xl font-semibold text-foreground">
          Tip any developer
          <span class="text-success drop-shadow-[0_1px_5px_#34d39980]">
            instantly
          </span>
        </div>
        <div class="text-base font-medium text-muted-foreground">
          Thank OSS maintainers and contributors on GitHub
        </div>
      </.card_header>
      <.card_content>
        <.simple_form for={@tip_form} phx-submit="create_tip">
          <div class="flex flex-col gap-6">
            <.input
              label="Contribution URL"
              field={@tip_form[:url]}
              placeholder="https://github.com/owner/repo/pull/123"
            />
            <div class="grid sm:grid-cols-2 gap-x-3 gap-y-6">
              <.input label="GitHub handle" field={@tip_form[:github_handle]} placeholder="jsmith" />
              <.input label="Amount" icon="tabler-currency-dollar" field={@tip_form[:amount]} />
            </div>
            <p class="text-sm text-muted-foreground">
              <.icon name="tabler-sparkles" class="size-4 text-current mr-1" /> Comment
              <code class="px-1 py-0.5 text-success">/tip $100 @handle</code>
              on GitHub issues and PRs
              <button
                :if={@installations == []}
                type="button"
                phx-click="install_app"
                class="hover:underline"
              >
                (requires the Algora app)
              </button>
            </p>
            <div class="flex justify-end gap-4">
              <.button>Submit</.button>
            </div>
          </div>
        </.simple_form>
      </.card_content>
    </.card>
    """
  end

  defp sidebar(assigns) do
    ~H"""
    <aside class="scrollbar-thin fixed top-16 right-0 bottom-0 hidden w-96 h-full overflow-y-auto border-l border-border bg-background p-4 pt-6 sm:p-6 md:p-8 lg:block">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-semibold leading-none tracking-tight">Getting started</h2>
      </div>
      <nav class="pt-6">
        <ol role="list" class="space-y-6">
          <%= for achievement <- @achievements do %>
            <li class="space-y-6">
              <.achievement achievement={achievement} />
              <.achievement_todo
                achievement={achievement}
                current_user={@current_user}
                secret_code={@secret_code}
                login_form={@login_form}
              />
            </li>
          <% end %>
        </ol>
      </nav>
      <div class="pt-12 flex items-center justify-between">
        <h2 class="text-xl font-semibold leading-none tracking-tight">Share your bounty board</h2>
      </div>
      <.badge
        id="og-url"
        phx-hook="CopyToClipboard"
        data-value={url(~p"/org/#{@current_org.handle}/home")}
        data-notice="Copied to clipboard!"
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
        <.icon id="og-url-copy-icon" name="tabler-copy" class="absolute left-1 my-auto size-4 mr-2" />
        <.icon
          id="og-url-check-icon"
          name="tabler-check"
          class="absolute left-1 my-auto hidden size-4 mr-2"
        />
        <span class="pl-4">{AlgoraWeb.Endpoint.host()}{~p"/org/#{@current_org.handle}/home"}</span>
      </.badge>
      <img
        src={~p"/og/org/#{@current_org.handle}/home"}
        alt={@current_org.name}
        class="mt-3 w-full aspect-[1200/630] rounded-lg ring-1 ring-input bg-black"
      />
      <div class="fixed right-0 bottom-0 hidden w-96 p-4 pr-0 pt-6 sm:p-6 sm:pr-0 md:py-8 md:pr-0 lg:grid lg:grid-cols-2 gap-2 gap-x-4 text-sm">
        <div class="flex items-center gap-2">
          <div class="flex -space-x-2">
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
          Chat with founders
        </div>
        <div class="flex items-center gap-2">
          <.icon name="tabler-brand-x" class="size-6 text-muted-foreground" /> @algoraio
        </div>
        <div class="flex items-center gap-2">
          <.icon name="tabler-phone" class="size-6 text-muted-foreground" /> +1 (650) 420-2207
        </div>
        <div class="flex items-center gap-2">
          <.icon name="tabler-mail" class="size-6 text-muted-foreground" /> support@algora.io
        </div>
      </div>
    </aside>
    """
  end

  defp share_drawer_header(%{share_drawer_type: "contract"} = assigns) do
    ~H"""
    <.drawer_header>
      <.drawer_title>Offer Contract</.drawer_title>
      <.drawer_description>
        Once you send an offer, {@selected_developer.name} will be notified and can accept or decline.
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
        <.card_content>
          <div class="space-y-4">
            <.input
              label="Hourly Rate"
              icon="tabler-currency-dollar"
              field={@contract_form[:hourly_rate]}
            />
            <.input label="Hours per Week" field={@contract_form[:hours_per_week]} />
          </div>
        </.card_content>
      </.card>

      <div class="ml-auto flex gap-4">
        <.button variant="secondary" phx-click="close_share_drawer" type="button">
          Cancel
        </.button>
        <.button type="submit">
          Send Contract Offer <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
        </.button>
      </div>
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
        <.card_content>
          <div class="space-y-4">
            <.input
              label="URL"
              field={@bounty_form[:url]}
              placeholder="https://github.com/owner/repo/issues/123"
            />
            <.input label="Amount" icon="tabler-currency-dollar" field={@bounty_form[:amount]} />
          </div>
        </.card_content>
      </.card>

      <div class="ml-auto flex gap-4">
        <.button variant="secondary" phx-click="close_share_drawer" type="button">
          Cancel
        </.button>
        <.button type="submit">
          Share Bounty <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
        </.button>
      </div>
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
        <.card_content>
          <div class="space-y-4">
            <.input label="Amount" icon="tabler-currency-dollar" field={@tip_form[:amount]} />
            <.input
              label="URL"
              field={@tip_form[:url]}
              placeholder="https://github.com/owner/repo/issues/123"
              helptext="We'll add a comment to the issue to notify the developer."
            />
          </div>
        </.card_content>
      </.card>

      <div class="ml-auto flex gap-4">
        <.button variant="secondary" phx-click="close_share_drawer" type="button">
          Cancel
        </.button>
        <.button type="submit">
          Send Tip <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
        </.button>
      </div>
    </.form>
    """
  end

  defp share_drawer_developer_info(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <.card_title>Developer</.card_title>
      </.card_header>
      <.card_content>
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
    <.drawer show={@show_share_drawer} direction="right" on_cancel="close_share_drawer">
      <.share_drawer_header
        :if={@selected_developer}
        selected_developer={@selected_developer}
        share_drawer_type={@share_drawer_type}
      />
      <.drawer_content :if={@selected_developer} class="mt-4">
        <div class="flex flex-col gap-8">
          <.share_drawer_developer_info selected_developer={@selected_developer} />
          <%= if incomplete?(@achievements, :connect_github_status) do %>
            <div class="relative">
              <div class="absolute inset-0 z-10 bg-background/50" />
              <div class="pointer-events-none">
                <.share_drawer_content
                  :if={@selected_developer}
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
end
