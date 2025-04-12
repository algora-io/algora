defmodule AlgoraWeb.BountyLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Admin
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.LineItem
  alias Algora.Chat
  alias Algora.Organizations.Member
  alias Algora.Repo
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
      field :amount, Algora.Types.USD
      field :github_handle, :string
      field :tip_percentage, :decimal
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:amount, :tip_percentage, :github_handle])
      |> validate_required([:amount, :github_handle])
      |> validate_number(:tip_percentage, greater_than_or_equal_to: 0)
      |> Algora.Validations.validate_money_positive(:amount)
    end
  end

  defmodule ExclusiveBountyForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :github_handle, :string
      field :deadline, :date
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:github_handle, :deadline])
      |> validate_required([:github_handle])
      |> Algora.Validations.validate_date_in_future(:deadline)
    end
  end

  @impl true
  def mount(%{"id" => bounty_id}, _session, socket) do
    bounty =
      Bounty
      |> Repo.get!(bounty_id)
      |> Repo.preload([:owner, :creator, :transactions, ticket: [repository: [:user]]])

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

    reward_changeset =
      RewardBountyForm.changeset(%RewardBountyForm{}, %{
        tip_percentage: 0,
        amount: bounty.amount
      })

    exclusive_changeset = ExclusiveBountyForm.changeset(%ExclusiveBountyForm{}, %{})

    {:ok, thread} = Chat.get_or_create_bounty_thread(bounty)
    messages = thread.id |> Chat.list_messages() |> Repo.preload(:sender)
    participants = thread.id |> Chat.list_participants() |> Repo.preload(:user)

    if connected?(socket) do
      Chat.subscribe(thread.id)
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
     |> assign(:show_exclusive_modal, false)
     |> assign(:selected_context, nil)
     |> assign(:recipient, nil)
     |> assign(:line_items, [])
     |> assign(:thread, thread)
     |> assign(:messages, messages)
     |> assign(:participants, participants)
     |> assign(:reward_form, to_form(reward_changeset))
     |> assign(:exclusive_form, to_form(exclusive_changeset))
     |> assign_exclusives(bounty.shared_with)
     |> assign_line_items()}
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
  def handle_event("exclusive", _params, socket) do
    {:noreply, assign(socket, :show_exclusive_modal, true)}
  end

  @impl true
  def handle_event("close_drawer", _params, socket) do
    {:noreply, close_drawers(socket)}
  end

  @impl true
  def handle_event("validate_reward", %{"reward_bounty_form" => params}, socket) do
    {:noreply,
     socket
     |> assign(:reward_form, to_form(RewardBountyForm.changeset(%RewardBountyForm{}, params)))
     |> assign_line_items()}
  end

  @impl true
  def handle_event("assign_line_items", %{"reward_bounty_form" => params}, socket) do
    {:noreply,
     socket
     |> assign_recipient(params["github_handle"])
     |> assign_line_items()}
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
  def handle_event("validate_exclusive", %{"exclusive_bounty_form" => params}, socket) do
    {:noreply, assign(socket, :exclusive_form, to_form(ExclusiveBountyForm.changeset(%ExclusiveBountyForm{}, params)))}
  end

  @impl true
  def handle_event("share_exclusive", %{"exclusive_bounty_form" => params}, socket) do
    changeset = ExclusiveBountyForm.changeset(%ExclusiveBountyForm{}, params)
    bounty = socket.assigns.bounty

    case apply_action(changeset, :save) do
      {:ok, data} ->
        with {:ok, token} <- Accounts.get_access_token(socket.assigns.current_user),
             {:ok, user} <- Workspace.ensure_user(token, data.github_handle),
             shared_with = Enum.uniq(bounty.shared_with ++ [user.provider_id]),
             {:ok, bounty} <-
               bounty
               |> Bounty.settings_changeset(%{
                 shared_with: shared_with,
                 deadline: if(data.deadline, do: DateTime.new!(data.deadline, ~T[00:00:00], "Etc/UTC"))
               })
               |> Repo.update() do
          {:noreply,
           socket
           |> put_flash(:info, "Bounty shared!")
           |> assign(:bounty, bounty)
           |> assign_exclusives(shared_with)
           |> close_drawers()}
        else
          nil ->
            {:noreply, put_flash(socket, :error, "User not found")}

          {:error, reason} ->
            Logger.error("Failed to share bounty: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Something went wrong")}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, :exclusive_form, to_form(changeset))}
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
                <div class="flex flex-col gap-4 xl:flex-row xl:items-center">
                  <.avatar class="h-12 w-12 sm:h-20 sm:w-20 rounded-lg sm:rounded-2xl">
                    <.avatar_image src={@host.avatar_url} />
                    <.avatar_fallback>
                      {Util.initials(User.handle(@host))}
                    </.avatar_fallback>
                  </.avatar>
                  <div>
                    <.link
                      href={@ticket.url}
                      target="_blank"
                      rel="noopener"
                      class="block text-xl sm:text-3xl font-semibold text-foreground/90 hover:underline"
                    >
                      {@ticket.title}
                    </.link>
                    <.link
                      href={@ticket.url}
                      target="_blank"
                      rel="noopener"
                      class="block text-base font-display sm:text-xl font-medium text-muted-foreground hover:underline"
                    >
                      {@host.provider_login}<span :if={@ticket.repository}>/{@ticket.repository.name}#{@ticket.number}</span>
                    </.link>
                  </div>
                </div>
                <div class="flex flex-col gap-4">
                  <div class="font-display tabular-nums text-5xl text-success-400 font-bold">
                    {Money.to_string!(@bounty.amount)}
                  </div>
                  <.button :if={@can_create_bounty} phx-click="reward">
                    Reward
                  </.button>
                </div>
              </div>
            </.card_content>
          </.card>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.card class="flex flex-col items-between justify-center">
              <.card_content>
                <div class="flex items-center justify-between gap-6">
                  <div class="shrink-1">
                    <.card_title>
                      Share on socials
                    </.card_title>
                    <div class="pt-4 flex gap-3 items-center">
                      <.social_share_button
                        id="twitter-share-url"
                        icon="tabler-brand-x"
                        value={@share_url}
                      />
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
                  </div>
                  <div class="relative aspect-[1200/630] max-w-[11rem] rounded-lg ring-1 ring-input bg-black">
                    <img
                      src={~p"/og/0/bounties/#{@bounty.id}"}
                      alt={@bounty.ticket.title}
                      class="object-cover"
                      loading="lazy"
                    />
                  </div>
                </div>
              </.card_content>
            </.card>
            <.card class="flex flex-col items-between justify-center">
              <.card_content>
                <div class="flex items-center justify-between gap-2">
                  <div>
                    <.card_title>
                      Exclusives
                    </.card_title>
                    <div class="flex items-center">
                      <span class="text-sm text-muted-foreground whitespace-nowrap">
                        <%= if @bounty.deadline do %>
                          Expires on {Calendar.strftime(@bounty.deadline, "%b %d, %Y")}
                          <.button
                            :if={@can_create_bounty}
                            variant="ghost"
                            size="icon-sm"
                            phx-click="exclusive"
                            class="group h-6 w-6"
                          >
                            <.icon
                              name="tabler-pencil"
                              class="h-4 w-4 text-muted-foreground group-hover:text-foreground"
                            />
                          </.button>
                        <% else %>
                          <span
                            :if={@exclusives != [] and @can_create_bounty}
                            class="underline cursor-pointer"
                            phx-click="exclusive"
                          >
                            Add a deadline
                          </span>
                        <% end %>
                      </span>
                    </div>
                    <.button
                      :if={@can_create_bounty}
                      variant="secondary"
                      phx-click="exclusive"
                      class="mt-3"
                    >
                      <.icon name="tabler-user-plus" class="size-5 mr-2 -ml-1" /> Add
                    </.button>
                    <div :if={@exclusives == [] and !@can_create_bounty} class="pt-2">
                      Open to everyone
                    </div>
                  </div>
                  <div class="flex flex-col gap-4">
                    <%= for user <- @exclusives do %>
                      <div class="flex justify-between text-sm">
                        <span>
                          <div class="flex items-center gap-4">
                            <.avatar>
                              <.avatar_image src={user.avatar_url} />
                              <.avatar_fallback>{Util.initials(user.name)}</.avatar_fallback>
                            </.avatar>
                            <div class="max-w-[6rem] sm:max-w-none">
                              <p class="font-medium truncate">
                                {user.name}
                              </p>
                              <p class="text-sm text-muted-foreground truncate">
                                @{user.provider_login}
                              </p>
                            </div>
                          </div>
                        </span>
                      </div>
                    <% end %>
                  </div>
                </div>
              </.card_content>
            </.card>
          </div>
          <.card>
            <.card_header>
              <.card_title>
                Description
              </.card_title>
            </.card_header>
            <.card_content>
              <div class="prose prose-invert">
                {Phoenix.HTML.raw(@ticket_body_html)}
              </div>
            </.card_content>
          </.card>
        </div>
      </.scroll_area>

      <div class="h-[calc(100svh-96px)] xl:w-[400px] flex xl:flex-none flex-col border rounded-xl">
        <div class="flex flex-none items-center justify-between border-b border-border bg-card/50 p-4 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div class="flex justify-between items-center w-full">
            <h2 class="text-lg font-semibold">
              Contributor chat
            </h2>

            <.avatar_group srcs={Enum.map(@participants, & &1.user.avatar_url)} />
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
          <!-- Add the emoji picker element (hidden by default) -->
          <div id="emoji-picker-container" class="bottom-[80px] absolute right-4 hidden">
            <emoji-picker></emoji-picker>
          </div>
        </div>
      </div>
    </div>

    <.drawer
      :if={@current_user}
      show={@show_exclusive_modal}
      on_cancel="close_drawer"
      direction="right"
    >
      <.drawer_header>
        <.drawer_title>Share</.drawer_title>
        <.drawer_description>
          Make this bounty exclusive to specific users
        </.drawer_description>
      </.drawer_header>
      <.drawer_content class="mt-4">
        <.form for={@exclusive_form} phx-change="validate_exclusive" phx-submit="share_exclusive">
          <div class="flex flex-col gap-8">
            <div class="space-y-4">
              <.input label="GitHub handle" field={@exclusive_form[:github_handle]} />
              <.input type="date" label="Deadline" field={@exclusive_form[:deadline]} />
            </div>
            <div class="ml-auto flex gap-4">
              <.button variant="secondary" phx-click="close_drawer" type="button">
                Cancel
              </.button>
              <.button type="submit">
                Submit
              </.button>
            </div>
          </div>
        </.form>
      </.drawer_content>
    </.drawer>
    <.drawer :if={@current_user} show={@show_reward_modal} on_cancel="close_drawer">
      <.drawer_header>
        <.drawer_title>Reward Bounty</.drawer_title>
        <.drawer_description>
          You can pay the full bounty now or start with a partial amount - it's up to you!
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
                <.card_content>
                  <div class="space-y-4">
                    <.input
                      label="Amount"
                      icon="tabler-currency-dollar"
                      field={@reward_form[:amount]}
                    />
                    <.input
                      label="GitHub handle"
                      field={@reward_form[:github_handle]}
                      phx-change="assign_line_items"
                      phx-debounce="500"
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
                <.card_content>
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

  defp assign_recipient(socket, github_handle) do
    case Workspace.ensure_user(Admin.token!(), github_handle) do
      {:ok, recipient} ->
        assign(socket, :recipient, recipient)

      _ ->
        assign(socket, :recipient, nil)
    end
  end

  defp assign_line_items(socket) do
    amount = calculate_final_amount(socket.assigns.reward_form.source)
    recipient = socket.assigns.recipient
    ticket_ref = socket.assigns.ticket_ref

    line_items =
      if recipient do
        []
      else
        [
          %LineItem{
            amount: amount,
            title: "Recipient",
            image: ~p"/images/placeholder-avatar.png",
            description: if(ticket_ref, do: "#{ticket_ref[:repo]}##{ticket_ref[:number]}")
          }
        ]
      end ++
        Bounties.generate_line_items(
          %{
            owner: socket.assigns.bounty.owner,
            amount: amount
          },
          ticket_ref: ticket_ref,
          recipient: recipient
        )

    assign(socket, :line_items, line_items)
  end

  defp reward_bounty(socket, bounty, changeset) do
    final_amount = calculate_final_amount(changeset)

    Bounties.reward_bounty(
      %{owner: bounty.owner, amount: final_amount, bounty_id: bounty.id, claims: []},
      ticket_ref: socket.assigns.ticket_ref,
      recipient: socket.assigns.recipient
    )
  end

  defp calculate_final_amount(data_or_changeset) do
    tip_percentage = get_field(data_or_changeset, :tip_percentage) || Decimal.new(0)
    amount = get_field(data_or_changeset, :amount) || Money.zero(:USD, no_fraction_if_integer: true)

    multiplier = tip_percentage |> Decimal.div(100) |> Decimal.add(1)
    Money.mult!(amount, multiplier)
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

  defp close_drawers(socket) do
    socket
    |> assign(:show_reward_modal, false)
    |> assign(:show_exclusive_modal, false)
  end

  defp assign_exclusives(socket, shared_with) do
    exclusives =
      Enum.flat_map(shared_with, fn provider_id ->
        case Workspace.ensure_user_by_provider_id(Admin.token!(), provider_id) do
          {:ok, user} -> [user]
          _ -> []
        end
      end)

    assign(socket, :exclusives, exclusives)
  end
end
