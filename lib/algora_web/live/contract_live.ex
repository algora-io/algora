defmodule AlgoraWeb.ContractLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Admin
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.LineItem
  alias Algora.Chat
  alias Algora.Organizations.Member
  alias Algora.Payments
  alias Algora.Repo
  alias Algora.Types.USD
  alias Algora.Util
  alias Algora.Workspace

  require Logger

  defp tip_options, do: [{"None", 0}, {"10%", 10}, {"20%", 20}, {"50%", 50}]

  defmodule RewardBountyForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :amount, USD
      field :tip_percentage, :decimal
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:amount, :tip_percentage])
      |> validate_required([:amount])
      |> validate_number(:tip_percentage, greater_than_or_equal_to: 0)
      |> Algora.Validations.validate_money_positive(:amount)
    end
  end

  @impl true
  def mount(%{"id" => bounty_id}, _session, socket) do
    bounty =
      Bounty
      |> Repo.get!(bounty_id)
      |> Repo.preload([:owner, :creator, :transactions, ticket: [repository: [:user]]])

    timezone = if(params = get_connect_params(socket), do: params["timezone"])

    {host, ticket_ref} =
      if bounty.ticket.repository do
        {bounty.ticket.repository.user,
         %{
           owner: bounty.ticket.repository.user.provider_login,
           repo: bounty.ticket.repository.name,
           number: bounty.ticket.number
         }}
      else
        {bounty.owner, nil}
      end

    socket
    |> assign(:bounty, bounty)
    |> assign(:ticket_ref, ticket_ref)
    |> assign(:host, host)
    |> assign(:timezone, timezone)
    |> on_mount(bounty)
  end

  @impl true
  def mount(%{"repo_owner" => repo_owner, "repo_name" => repo_name, "number" => number}, _session, socket) do
    number = String.to_integer(number)

    ticket_ref = %{owner: repo_owner, repo: repo_name, number: number}

    bounty =
      from(b in Bounty,
        join: t in assoc(b, :ticket),
        join: r in assoc(t, :repository),
        join: u in assoc(r, :user),
        where: u.provider == "github",
        where: u.provider_login == ^repo_owner,
        where: r.name == ^repo_name,
        where: t.number == ^number,
        order_by: fragment("CASE WHEN ? = ? THEN 0 ELSE 1 END", u.id, ^socket.assigns.current_org.id),
        limit: 1
      )
      |> Repo.one()
      |> Repo.preload([:owner, :creator, :transactions, ticket: [repository: [:user]]])

    socket
    |> assign(:bounty, bounty)
    |> assign(:ticket_ref, ticket_ref)
    |> assign(:host, bounty.ticket.repository.user)
    |> on_mount(bounty)
  end

  defp on_mount(socket, bounty) do
    debits = Enum.filter(bounty.transactions, &(&1.type == :debit and &1.status == :succeeded))

    total_paid =
      debits
      |> Enum.map(& &1.net_amount)
      |> Enum.reduce(Money.zero(:USD, no_fraction_if_integer: true), &Money.add!(&1, &2))

    ticket_body_html = Algora.Markdown.render(bounty.ticket.description)

    reward_changeset = RewardBountyForm.changeset(%RewardBountyForm{}, %{amount: bounty.amount, tip_percentage: 0})

    {:ok, thread} = Chat.get_or_create_bounty_thread(bounty)
    messages = thread.id |> Chat.list_messages() |> Repo.preload(:sender)
    participants = thread.id |> Chat.list_participants() |> Repo.preload(:user)

    if connected?(socket) do
      Chat.subscribe(thread.id)
      Payments.subscribe()
    end

    share_url =
      if socket.assigns.ticket_ref do
        url(
          ~p"/#{socket.assigns.ticket_ref.owner}/#{socket.assigns.ticket_ref.repo}/issues/#{socket.assigns.ticket_ref.number}"
        )
      else
        url(~p"/#{socket.assigns.bounty.owner.handle}/bounties/#{socket.assigns.bounty.id}")
      end

    {:ok,
     socket
     |> assign(:can_create_bounty, Member.can_create_bounty?(socket.assigns.current_user_role))
     |> assign(:share_url, share_url)
     |> assign(:page_title, bounty.ticket.title)
     |> assign(:ticket, bounty.ticket)
     |> assign(:total_paid, total_paid)
     |> assign(:ticket_body_html, ticket_body_html)
     |> assign(:show_reward_modal, false)
     |> assign(:show_authorize_modal, false)
     |> assign(:selected_context, nil)
     |> assign(:line_items, [])
     |> assign(:thread, thread)
     |> assign(:messages, messages)
     |> assign(:participants, participants)
     |> assign(:reward_form, to_form(reward_changeset))
     |> assign_contractor(bounty.shared_with)
     |> assign_transactions()
     |> assign_line_items(reward_changeset)}
  end

  @impl true
  def handle_params(_params, _url, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Chat.MessageCreated{message: message, participant: participant}, socket) do
    socket =
      if message.id in Enum.map(socket.assigns.messages, & &1.id),
        do: socket,
        else: Phoenix.Component.update(socket, :messages, &(&1 ++ [message]))

    socket =
      if participant.id in Enum.map(socket.assigns.participants, & &1.id),
        do: socket,
        else: Phoenix.Component.update(socket, :participants, &(&1 ++ [participant]))

    {:noreply, socket}
  end

  def handle_info(:payments_updated, socket) do
    {:noreply, assign_transactions(socket)}
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
  def handle_event("reward", _params, socket) do
    {:noreply, assign(socket, :show_reward_modal, true)}
  end

  @impl true
  def handle_event("authorize", _params, socket) do
    {:noreply, assign(socket, :show_authorize_modal, true)}
  end

  @impl true
  def handle_event("close_drawer", _params, socket) do
    {:noreply, close_drawers(socket)}
  end

  @impl true
  def handle_event("validate_reward", %{"reward_bounty_form" => params}, socket) do
    changeset = RewardBountyForm.changeset(%RewardBountyForm{}, params)

    {:noreply,
     socket
     |> assign(:reward_form, to_form(changeset))
     |> assign_line_items(changeset)}
  end

  @impl true
  def handle_event("pay_with_stripe", %{"reward_bounty_form" => params}, socket) do
    changeset = RewardBountyForm.changeset(%RewardBountyForm{}, params)

    case apply_action(changeset, :save) do
      {:ok, _data} ->
        case reward_bounty(socket, socket.assigns.bounty, changeset) do
          {:ok, session_url} ->
            {:noreply, redirect(socket, external: session_url)}

          {:error, reason} ->
            Logger.error("Failed to create payment session: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Something went wrong")}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, :reward_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("authorize_with_stripe", _params, socket) do
    case authorize_payment(socket, socket.assigns.bounty) do
      {:ok, session_url} ->
        {:noreply, redirect(socket, external: session_url)}

      {:error, reason} ->
        Logger.error("Failed to create payment session: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Something went wrong")}
    end
  end

  @impl true
  def handle_event("release_funds", %{"tx_id" => tx_id}, socket) do
    with tx when not is_nil(tx) <- Enum.find(socket.assigns.transactions, &(&1.id == tx_id)),
         {:ok, charge} <- Algora.PSP.Charge.retrieve(tx.provider_charge_id),
         {:ok, _} <- Algora.Payments.process_charge("charge.succeeded", charge, tx.group_id) do
      {:noreply, socket}
    else
      {:error, reason} ->
        Logger.error("Failed to release funds: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Something went wrong")}

      _ ->
        Logger.error("Failed to release funds: transaction not found")
        {:noreply, put_flash(socket, :error, "Something went wrong")}
    end
  end

  @impl true
  def handle_event("accept_contract", %{"tx_id" => tx_id}, socket) do
    with tx when not is_nil(tx) <- Enum.find(socket.assigns.transactions, &(&1.id == tx_id)),
         {:ok, _payment_intent} <- Algora.PSP.PaymentIntent.capture(tx.provider_payment_intent_id) do
      {:noreply, put_flash(socket, :info, "Contract accepted!")}
    else
      {:error, reason} ->
        Logger.error("Failed to capture payment intent: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Something went wrong")}

      _ ->
        Logger.error("Failed to release funds: transaction not found")
        {:noreply, put_flash(socket, :error, "Something went wrong")}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={classes(["xl:flex p-4", if(!@current_user, do: "pb-16 xl:pb-24")])}>
      <.scroll_area class="xl:h-[calc(100svh-96px)] flex-1 pr-6">
        <div class="space-y-4">
          <.card>
            <.card_content>
              <div class="flex flex-col xl:flex-row xl:justify-between gap-4">
                <div class="flex items-center gap-4">
                  <div class="flex -space-x-2">
                    <.avatar class="h-12 w-12 ring-2 ring-background">
                      <.avatar_image src={@bounty.owner.avatar_url} />
                      <.avatar_fallback>
                        {Util.initials(@bounty.owner.name)}
                      </.avatar_fallback>
                    </.avatar>
                    <.avatar class="h-12 w-12 ring-2 ring-background">
                      <.avatar_image src={@contractor.avatar_url} />
                      <.avatar_fallback>
                        {Util.initials(@contractor.name)}
                      </.avatar_fallback>
                    </.avatar>
                  </div>
                  <div>
                    <h1 class="text-2xl font-semibold">
                      {@bounty.ticket.title}
                    </h1>
                    <div class="text-sm text-muted-foreground space-x-2">
                      <span>Created {Calendar.strftime(@bounty.inserted_at, "%b %d, %Y")}</span>
                      <span
                        :if={@bounty.hours_per_week && @bounty.hours_per_week > 0}
                        class="space-x-2"
                      >
                        <.icon name="tabler-clock" class="h-4 w-4" />
                        {@bounty.hours_per_week} hours per week
                      </span>
                    </div>
                  </div>
                </div>
                <%= if transaction = Enum.find(@transactions, fn tx -> tx.type == :charge and tx.status == :requires_capture end) do %>
                  <%= if @current_user && @current_user.id == @contractor.id do %>
                    <.button
                      phx-click="accept_contract"
                      phx-disable-with="Accepting..."
                      phx-value-tx_id={transaction.id}
                    >
                      Accept contract
                    </.button>
                  <% else %>
                    <.badge variant="warning" class="mb-auto">
                      Offer sent
                    </.badge>
                  <% end %>
                <% end %>

                <%= if _transaction = Enum.find(@transactions, fn tx -> tx.type == :debit end) do %>
                  <div class="flex flex-col gap-4 items-end">
                    <.badge variant="success" class="mb-auto">
                      Active
                    </.badge>
                  </div>
                <% end %>

                <%= if @can_create_bounty && @transactions == [] do %>
                  <.button phx-click="reward">
                    Make payment
                  </.button>
                <% end %>
              </div>
            </.card_content>
          </.card>
          <.card :if={@ticket_body_html}>
            <.card_header>
              <.card_title>
                Description
              </.card_title>
            </.card_header>
            <.card_content class="pt-0">
              <div class="prose prose-invert">
                {Phoenix.HTML.raw(@ticket_body_html)}
              </div>
            </.card_content>
          </.card>
          <.card :if={length(@transactions) == 0 and @can_create_bounty}>
            <.card_header>
              <.card_title>
                Finalize offer
              </.card_title>
            </.card_header>
            <.card_content class="pt-0">
              <div class="flex flex-col xl:flex-row xl:justify-between gap-4">
                <ul class="space-y-2">
                  <li class="flex items-center">
                    <.icon name="tabler-circle-number-1 mr-2" class="size-8 text-success-400" />
                    Authorize the payment to share the contract offer with {@contractor.name}
                  </li>
                  <li class="flex items-center">
                    <.icon name="tabler-circle-number-2 mr-2" class="size-8 text-success-400" />
                    When {@contractor.name} accepts, you will be charged
                    <span class="font-semibold font-display px-1">
                      {Money.to_string!(Money.mult!(@bounty.amount, Decimal.new("1.13")))}
                    </span>
                    into escrow
                  </li>
                  <li class="flex items-center">
                    <.icon name="tabler-circle-number-3 mr-2" class="size-8 text-success-400" />
                    At the end of the week, release or withhold the funds based on {@contractor.name}'s performance
                  </li>
                </ul>

                <dl class="-mt-12 space-y-4">
                  <dd class="font-display tabular-nums text-5xl text-success-400 font-bold">
                    {Money.to_string!(Money.mult!(@bounty.amount, Decimal.new("1.13")))}
                  </dd>
                  <div class="flex justify-between">
                    <dt class="text-foreground">
                      Total amount for <span class="font-semibold">{@bounty.hours_per_week}</span>
                      hours
                      <div class="text-xs text-muted-foreground">
                        (includes all platform and payment processing fees)
                      </div>
                    </dt>
                  </div>
                  <.button phx-click="authorize">
                    Authorize
                  </.button>
                </dl>
              </div>
            </.card_content>
          </.card>
          <.card :if={length(@transactions) > 0}>
            <.card_header>
              <.card_title>
                <div class="flex justify-between gap-4">
                  Timeline
                  <%= if @can_create_bounty do %>
                    <%= if _transaction = Enum.find(@transactions, fn tx -> tx.type == :debit and tx.status == :succeeded end) do %>
                      <.button phx-click="reward">
                        Make payment
                      </.button>
                    <% end %>
                  <% end %>
                </div>
              </.card_title>
            </.card_header>
            <.card_content class="pt-0">
              <div class="-mx-6 -mt-3.5 overflow-x-auto">
                <div class="inline-block min-w-full align-middle">
                  <table class="min-w-full divide-y divide-border">
                    <thead>
                      <tr>
                        <th scope="col" class="px-6 py-3.5 text-left text-sm font-semibold">Date</th>
                        <th scope="col" class="px-6 py-3.5 text-left text-sm font-semibold">
                          Description
                        </th>
                        <th scope="col" class="px-6 py-3.5 text-right text-sm font-semibold">
                          Amount
                        </th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-border">
                      <%= for transaction <- @transactions do %>
                        <tr
                          :if={@can_create_bounty or transaction.status != :requires_release}
                          class="hover:bg-muted/50"
                        >
                          <td class="whitespace-nowrap px-6 py-4 text-sm">
                            <div :if={@timezone}>
                              {Util.timestamp(transaction.inserted_at, @timezone)}
                            </div>
                            <div
                              :if={!@timezone}
                              class="h-[24px] w-[132px] bg-muted animate-pulse rounded-lg"
                            >
                            </div>
                          </td>
                          <td class="whitespace-nowrap px-6 py-4 text-sm">
                            <div class="flex flex-col items-start gap-2">
                              {description(transaction)}
                              <.button
                                :if={
                                  transaction.type == :debit and
                                    transaction.status == :requires_release
                                }
                                size="sm"
                                phx-click="release_funds"
                                phx-disable-with="Releasing..."
                                phx-value-tx_id={transaction.id}
                              >
                                Release funds
                              </.button>
                            </div>
                          </td>
                          <td class="font-display whitespace-nowrap px-6 py-4 text-right font-medium tabular-nums">
                            <span class={transaction_color(transaction)}>
                              {Money.to_string!(transaction.net_amount)}
                            </span>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </div>
            </.card_content>
          </.card>
        </div>
      </.scroll_area>

      <div class="h-[calc(100svh-96px)] xl:w-[400px] flex xl:flex-none flex-col border rounded-xl">
        <div class="flex flex-none items-center justify-between border-b border-border bg-card/50 p-4 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div class="flex items-center gap-3">
            <div class="relative">
              <.avatar>
                <.avatar_image src={@contractor.avatar_url} alt="Developer avatar" />
                <.avatar_fallback>
                  {Util.initials(@contractor.name)}
                </.avatar_fallback>
              </.avatar>
              <%!-- <div class="absolute right-0 bottom-0 h-3 w-3 rounded-full border-2 border-background bg-success">
              </div> --%>
            </div>
            <div>
              <h2 class="text-lg font-semibold">{@contractor.name}</h2>
              <p :if={@contractor.last_active_at} class="text-xs text-muted-foreground">
                Active {Util.time_ago(@contractor.last_active_at)}
              </p>
              <p :if={!@contractor.last_active_at} class="text-xs text-muted-foreground">
                Offline
              </p>
            </div>
          </div>
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
                        {Util.initials(message.sender.name)}
                      </.avatar_fallback>
                    </.avatar>
                    <div class="max-w-[80%] relative rounded-2xl rounded-tl-none bg-muted p-3 break-words">
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
          <!-- Add the emoji picker element (hidden by default) -->
          <div id="emoji-picker-container" class="bottom-[80px] absolute right-4 hidden">
            <emoji-picker></emoji-picker>
          </div>
        </div>
      </div>
    </div>

    <.drawer :if={@current_user} show={@show_authorize_modal} on_cancel="close_drawer">
      <.drawer_header>
        <.drawer_title>Authorize payment</.drawer_title>
        <.drawer_description>
          You will be charged once {@contractor.name} accepts the contract.
        </.drawer_description>
      </.drawer_header>
      <.drawer_content class="mt-4">
        <.form for={@reward_form} phx-change="validate_reward" phx-submit="authorize_with_stripe">
          <div class="flex flex-col gap-8">
            <div class="grid grid-cols-2 gap-8">
              <.card>
                <.card_header>
                  <.card_title>Payment Details</.card_title>
                </.card_header>
                <.card_content class="pt-0">
                  <div class="space-y-4">
                    <.input
                      label="Amount"
                      icon="tabler-currency-dollar"
                      field={@reward_form[:amount]}
                      disabled
                    />
                  </div>
                </.card_content>
              </.card>
              <.card>
                <.card_header>
                  <.card_title>Payment Summary</.card_title>
                </.card_header>
                <.card_content class="pt-0">
                  <dl class="space-y-4">
                    <%= for line_item <- @line_items do %>
                      <div class="flex justify-between">
                        <dt class="flex items-center gap-4">
                          <%= if line_item.image do %>
                            <.avatar>
                              <.avatar_image src={line_item.image} />
                              <.avatar_fallback>
                                {Util.initials(line_item.title)}
                              </.avatar_fallback>
                            </.avatar>
                          <% else %>
                            <div class="w-10" />
                          <% end %>
                          <div>
                            <div class="font-medium">{line_item.title}</div>
                            <div class="text-muted-foreground text-sm">{line_item.description}</div>
                          </div>
                        </dt>
                        <dd class="font-display font-semibold tabular-nums">
                          {Money.to_string!(line_item.amount)}
                        </dd>
                      </div>
                    <% end %>
                    <div class="h-px bg-border" />
                    <div class="flex justify-between">
                      <dt class="flex items-center gap-4">
                        <div class="w-10" />
                        <div class="font-medium">Total due</div>
                      </dt>
                      <dd class="font-display font-semibold tabular-nums">
                        {LineItem.gross_amount(@line_items)}
                      </dd>
                    </div>
                  </dl>
                </.card_content>
              </.card>
            </div>
            <div class="ml-auto flex gap-4">
              <.button variant="secondary" phx-click="close_drawer" type="button">
                Cancel
              </.button>
              <.button type="submit">
                Authorize with Stripe <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
              </.button>
            </div>
          </div>
        </.form>
      </.drawer_content>
    </.drawer>
    <.drawer :if={@current_user} show={@show_reward_modal} on_cancel="close_drawer">
      <.drawer_header>
        <.drawer_title>Pay contract</.drawer_title>
        <.drawer_description>
          You can pay any amount at any time.
        </.drawer_description>
      </.drawer_header>
      <.drawer_content class="mt-4">
        <.form for={@reward_form} phx-change="validate_reward" phx-submit="pay_with_stripe">
          <div class="flex flex-col gap-8">
            <div class="grid grid-cols-2 gap-8">
              <.card>
                <.card_header>
                  <.card_title>Payment Details</.card_title>
                </.card_header>
                <.card_content class="pt-0">
                  <div class="space-y-4">
                    <.input
                      label="Amount"
                      icon="tabler-currency-dollar"
                      field={@reward_form[:amount]}
                    />

                    <div>
                      <.label>Tip</.label>
                      <div class="mt-2">
                        <.radio_group
                          class="grid grid-cols-4 gap-4"
                          field={@reward_form[:tip_percentage]}
                          options={tip_options()}
                        />
                      </div>
                    </div>
                  </div>
                </.card_content>
              </.card>
              <.card>
                <.card_header>
                  <.card_title>Payment Summary</.card_title>
                </.card_header>
                <.card_content class="pt-0">
                  <dl class="space-y-4">
                    <%= for line_item <- @line_items do %>
                      <div class="flex justify-between">
                        <dt class="flex items-center gap-4">
                          <%= if line_item.image do %>
                            <.avatar>
                              <.avatar_image src={line_item.image} />
                              <.avatar_fallback>
                                {Util.initials(line_item.title)}
                              </.avatar_fallback>
                            </.avatar>
                          <% else %>
                            <div class="w-10" />
                          <% end %>
                          <div>
                            <div class="font-medium">{line_item.title}</div>
                            <div class="text-muted-foreground text-sm">{line_item.description}</div>
                          </div>
                        </dt>
                        <dd class="font-display font-semibold tabular-nums">
                          {Money.to_string!(line_item.amount)}
                        </dd>
                      </div>
                    <% end %>
                    <div class="h-px bg-border" />
                    <div class="flex justify-between">
                      <dt class="flex items-center gap-4">
                        <div class="w-10" />
                        <div class="font-medium">Total due</div>
                      </dt>
                      <dd class="font-display font-semibold tabular-nums">
                        {LineItem.gross_amount(@line_items)}
                      </dd>
                    </div>
                  </dl>
                </.card_content>
              </.card>
            </div>
            <div class="ml-auto flex gap-4">
              <.button variant="secondary" phx-click="close_drawer" type="button">
                Cancel
              </.button>
              <.button type="submit">
                Pay with Stripe <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
              </.button>
            </div>
          </div>
        </.form>
      </.drawer_content>
    </.drawer>
    """
  end

  defp assign_line_items(socket, changeset) do
    line_items =
      Bounties.generate_line_items(
        %{
          owner: socket.assigns.bounty.owner,
          amount: calculate_final_amount(changeset)
        },
        bounty: socket.assigns.bounty,
        ticket_ref: socket.assigns.ticket_ref,
        recipient: socket.assigns.contractor,
        contract_type: socket.assigns.bounty.contract_type
      )

    assign(socket, :line_items, line_items)
  end

  defp reward_bounty(socket, bounty, changeset) do
    final_amount = calculate_final_amount(changeset)

    Bounties.reward_bounty(
      %{owner: bounty.owner, amount: final_amount, bounty: bounty, claims: []},
      ticket_ref: socket.assigns.ticket_ref,
      recipient: socket.assigns.contractor
    )
  end

  defp authorize_payment(socket, bounty) do
    Bounties.authorize_payment(
      %{owner: bounty.owner, amount: bounty.amount, bounty: bounty, claims: []},
      ticket_ref: socket.assigns.ticket_ref,
      recipient: socket.assigns.contractor,
      success_url: url(~p"/#{bounty.owner.handle}/contracts/#{bounty.id}"),
      cancel_url: url(~p"/#{bounty.owner.handle}/contracts/#{bounty.id}")
    )
  end

  defp calculate_final_amount(data_or_changeset) do
    tip_percentage = get_field(data_or_changeset, :tip_percentage) || Decimal.new(0)
    amount = get_field(data_or_changeset, :amount) || Money.zero(:USD, no_fraction_if_integer: true)

    multiplier = tip_percentage |> Decimal.div(100) |> Decimal.add(1)
    Money.mult!(amount, multiplier)
  end

  defp close_drawers(socket) do
    socket
    |> assign(:show_reward_modal, false)
    |> assign(:show_authorize_modal, false)
  end

  defp assign_contractor(socket, shared_with) do
    contractor =
      shared_with
      |> Enum.flat_map(fn provider_id ->
        case Workspace.ensure_user_by_provider_id(Admin.token!(), provider_id) do
          {:ok, user} -> [user]
          _ -> []
        end
      end)
      |> List.first()

    assign(socket, :contractor, contractor)
  end

  defp assign_transactions(socket) do
    transactions =
      [
        user_id: socket.assigns.bounty.owner.id,
        status: [:succeeded, :requires_capture, :requires_release],
        bounty_id: socket.assigns.bounty.id
      ]
      |> Payments.list_transactions()
      |> Enum.filter(&(&1.type == :charge or &1.status in [:succeeded, :requires_release]))

    balance = calculate_balance(transactions)
    volume = calculate_volume(transactions)

    socket
    |> assign(:transactions, transactions)
    |> assign(:total_balance, balance)
    |> assign(:total_volume, volume)
  end

  defp calculate_balance(transactions) do
    transactions
    |> Enum.filter(&(&1.status == :succeeded))
    |> Enum.reduce(Money.new!(0, :USD), fn transaction, acc ->
      case transaction.type do
        type when type in [:charge, :deposit, :credit] ->
          Money.add!(acc, transaction.net_amount)

        type when type in [:debit, :withdrawal, :transfer] ->
          Money.sub!(acc, transaction.net_amount)

        _ ->
          acc
      end
    end)
  end

  defp calculate_volume(transactions) do
    transactions
    |> Enum.filter(&(&1.status == :succeeded))
    |> Enum.reduce(Money.new!(0, :USD), fn transaction, acc ->
      case transaction.type do
        type when type in [:charge, :credit] -> Money.add!(acc, transaction.net_amount)
        _ -> acc
      end
    end)
  end

  defp transaction_color(%{type: :debit, status: :requires_release}), do: "text-emerald-400/50"

  defp transaction_color(%{type: type}) do
    case type do
      t when t in [:charge, :credit, :deposit] -> "text-foreground"
      t when t in [:debit, :withdrawal, :transfer] -> "text-emerald-400"
    end
  end

  defp description(%{type: :charge, status: :requires_capture}), do: "Authorized"

  defp description(%{type: :charge, status: :succeeded}), do: "Escrowed"

  defp description(%{type: :debit, status: :requires_release}), do: "Ready to release"

  defp description(%{type: :debit, status: :succeeded}), do: "Released"

  defp description(%{type: _type}), do: nil
end
