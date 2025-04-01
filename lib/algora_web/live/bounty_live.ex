defmodule AlgoraWeb.BountyLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Changeset

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.LineItem
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace

  require Logger

  defp tip_options do
    [
      {"None", 0},
      {"10%", 10},
      {"20%", 20},
      {"50%", 50}
    ]
  end

  defmodule RewardBountyForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :amount, :decimal
      field :tip_percentage, :decimal
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:amount, :tip_percentage])
      |> validate_required([:amount])
      |> validate_number(:tip_percentage, greater_than_or_equal_to: 0)
      |> validate_number(:amount, greater_than: 0)
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
      |> validate_required([:github_handle, :deadline])
    end
  end

  @impl true
  def mount(%{"id" => bounty_id}, _session, socket) do
    bounty =
      Bounty
      |> Repo.get!(bounty_id)
      |> Repo.preload([
        :owner,
        :creator,
        :transactions,
        ticket: [repository: [:user]]
      ])

    debits = Enum.filter(bounty.transactions, &(&1.type == :debit and &1.status == :succeeded))

    total_paid =
      debits
      |> Enum.map(& &1.net_amount)
      |> Enum.reduce(Money.zero(:USD, no_fraction_if_integer: true), &Money.add!(&1, &2))

    ticket_body_html = Algora.Markdown.render(bounty.ticket.description)

    contexts = contexts(bounty)

    reward_changeset =
      RewardBountyForm.changeset(%RewardBountyForm{}, %{
        tip_percentage: 0,
        amount: Money.to_decimal(bounty.amount)
      })

    exclusive_changeset =
      ExclusiveBountyForm.changeset(%ExclusiveBountyForm{}, %{
        github_handle: "",
        deadline: Date.utc_today()
      })

    {:ok,
     socket
     |> assign(:page_title, bounty.ticket.title)
     |> assign(:bounty, bounty)
     |> assign(:ticket, bounty.ticket)
     |> assign(:total_paid, total_paid)
     |> assign(:ticket_body_html, ticket_body_html)
     |> assign(:contexts, contexts)
     |> assign(:show_reward_modal, false)
     |> assign(:show_exclusive_modal, false)
     |> assign(:selected_context, nil)
     |> assign(:line_items, [])
     |> assign(:messages, [])
     |> assign(:reward_form, to_form(reward_changeset))
     |> assign(:exclusive_form, to_form(exclusive_changeset))
     |> assign_exclusives(bounty.shared_with)}
  end

  @impl true
  def handle_params(_params, _url, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_params(%{"context" => context_id}, _url, socket) do
    {:noreply, socket |> assign_selected_context(context_id) |> assign_line_items()}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("reward", _params, socket) do
    {:noreply, assign(socket, :show_reward_modal, true)}
  end

  def handle_event("exclusive", _params, socket) do
    {:noreply, assign(socket, :show_exclusive_modal, true)}
  end

  def handle_event("close_drawer", _params, socket) do
    {:noreply, close_drawers(socket)}
  end

  def handle_event("validate_reward", %{"reward_bounty_form" => params}, socket) do
    {:noreply,
     socket
     |> assign(:reward_form, to_form(RewardBountyForm.changeset(%RewardBountyForm{}, params)))
     |> assign_line_items()}
  end

  def handle_event("pay_with_stripe", %{"reward_bounty_form" => params}, socket) do
    changeset = RewardBountyForm.changeset(%RewardBountyForm{}, params)

    case apply_action(changeset, :save) do
      {:ok, data} ->
        case create_payment_session(socket, data) do
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

  def handle_event("validate_exclusive", %{"exclusive_bounty_form" => params}, socket) do
    {:noreply,
     socket
     |> assign(:exclusive_form, to_form(ExclusiveBountyForm.changeset(%ExclusiveBountyForm{}, params)))
     |> assign_line_items()}
  end

  def handle_event("share_exclusive", %{"exclusive_bounty_form" => params}, socket) do
    changeset = ExclusiveBountyForm.changeset(%ExclusiveBountyForm{}, params)
    bounty = socket.assigns.bounty

    case apply_action(changeset, :save) do
      {:ok, data} ->
        with {:ok, token} <- Accounts.get_access_token(socket.assigns.current_user),
             {:ok, user} <- Workspace.ensure_user(token, data.github_handle),
             shared_with = Enum.uniq(bounty.shared_with ++ [user.provider_id]),
             {:ok, _} <- bounty |> Bounty.settings_changeset(%{shared_with: shared_with}) |> Repo.update() do
          {:noreply,
           socket
           |> put_flash(:info, "Bounty shared!")
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

  defp assign_selected_context(socket, context_id) do
    case Enum.find(socket.assigns.contexts, &(&1.id == context_id)) do
      nil ->
        socket

      context ->
        assign(socket, :selected_context, context)
    end
  end

  defp assign_line_items(socket) do
    # line_items =
    #   Bounties.generate_line_items(
    #     %{
    #       owner: socket.assigns.selected_context,
    #       amount: calculate_final_amount(socket.assigns.reward_form.source)
    #     },
    #     ticket_ref: ticket_ref(socket),
    #     recipient: socket.assigns.selected_context
    #   )

    line_items = []
    assign(socket, :line_items, line_items)
  end

  defp ticket_ref(socket) do
    %{
      owner: socket.assigns.ticket.repository.user.provider_login,
      repo: socket.assigns.ticket.repository.name,
      number: socket.assigns.ticket.number
    }
  end

  defp create_payment_session(socket, data) do
    final_amount = calculate_final_amount(data)

    Bounties.reward_bounty(
      %{
        owner: socket.assigns.current_user,
        amount: final_amount,
        bounty_id: socket.assigns.bounty.id,
        claims: []
      },
      ticket_ref: ticket_ref(socket),
      recipient: socket.assigns.selected_context
    )
  end

  defp calculate_final_amount(data_or_changeset) do
    tip_percentage = get_field(data_or_changeset, :tip_percentage) || Decimal.new(0)
    amount = get_field(data_or_changeset, :amount) || Decimal.new(0)

    multiplier = tip_percentage |> Decimal.div(100) |> Decimal.add(1)
    amount |> Money.new!(:USD) |> Money.mult!(multiplier)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex">
      <.scroll_area class="h-[calc(100vh-64px)] flex-1 p-4 pr-6">
        <div class="space-y-4">
          <.card>
            <.card_content>
              <div class="flex justify-between">
                <div class="flex gap-4 items-center">
                  <.avatar class="h-20 w-20 rounded-2xl">
                    <.avatar_image src={@ticket.repository.user.avatar_url} />
                    <.avatar_fallback>
                      {String.first(@ticket.repository.user.provider_login)}
                    </.avatar_fallback>
                  </.avatar>
                  <div>
                    <.link
                      href={@ticket.url}
                      class="text-4xl font-semibold hover:underline"
                      target="_blank"
                    >
                      {@ticket.title}
                    </.link>
                    <div class="pt-2 text-2xl font-medium text-muted-foreground">
                      {@ticket.repository.user.provider_login}/{@ticket.repository.name}#{@ticket.number}
                    </div>
                  </div>
                </div>
                <div class="flex flex-col gap-4">
                  <div class="font-display tabular-nums text-5xl text-success-400 font-bold">
                    {Money.to_string!(@bounty.amount)}
                  </div>
                  <.button phx-click="reward">
                    Reward
                  </.button>
                </div>
              </div>
            </.card_content>
          </.card>
          <div class="grid grid-cols-2 gap-4">
            <.card class="col">
              <.card_content>
                <div class="flex items-center justify-between">
                  <div>
                    <.card_title>
                      Exclusives
                    </.card_title>
                    <div class="flex items-center">
                      <span class="text-sm text-muted-foreground">
                        Expires on {Calendar.strftime(@bounty.inserted_at, "%b %d, %Y")}
                      </span>
                      <.button
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
                    </div>
                    <.button variant="secondary" phx-click="exclusive" class="mt-3">
                      <.icon name="tabler-user-plus" class="h-4 w-4 mr-2 -ml-1" /> Add
                    </.button>
                  </div>
                  <div class="flex flex-col gap-4">
                    <%= for user <- @exclusives do %>
                      <div class="flex justify-between text-sm">
                        <span>
                          <div class="flex items-center gap-4">
                            <.avatar>
                              <.avatar_image src={user.avatar_url} />
                              <.avatar_fallback>{String.first(user.name)}</.avatar_fallback>
                            </.avatar>
                            <div>
                              <p class="font-medium">{user.name}</p>
                              <p class="text-sm text-muted-foreground">@{user.provider_login}</p>
                            </div>
                          </div>
                        </span>
                      </div>
                    <% end %>
                  </div>
                </div>
              </.card_content>
            </.card>
            <.card>
              <.card_content>
                <div class="flex items-center justify-between">
                  <div>
                    <.card_title>
                      Share on socials
                    </.card_title>
                    <div class="pt-3 flex gap-3 items-center">
                      <.social_share_button
                        id="twitter-share-url"
                        icon="tabler-brand-x"
                        value={url(~p"/org/#{@bounty.owner.handle}/bounties/#{@bounty.id}")}
                      />
                      <.social_share_button
                        id="reddit-share-url"
                        icon="tabler-brand-reddit"
                        value={url(~p"/org/#{@bounty.owner.handle}/bounties/#{@bounty.id}")}
                      />
                      <.social_share_button
                        id="linkedin-share-url"
                        icon="tabler-brand-linkedin"
                        value={url(~p"/org/#{@bounty.owner.handle}/bounties/#{@bounty.id}")}
                      />
                      <.social_share_button
                        id="hackernews-share-url"
                        icon="tabler-brand-ycombinator"
                        value={url(~p"/org/#{@bounty.owner.handle}/bounties/#{@bounty.id}")}
                      />
                    </div>
                  </div>
                  <img
                    src={~p"/og/0/bounties/#{@bounty.id}"}
                    alt={@bounty.ticket.title}
                    class="mt-3 w-full aspect-[1200/630] max-w-[11rem] rounded-lg ring-1 ring-input bg-black"
                  />
                </div>
              </.card_content>
            </.card>
          </div>
          <.card>
            <.card_content>
              <div class="prose dark:prose-invert">
                {Phoenix.HTML.raw(@ticket_body_html)}
              </div>
            </.card_content>
          </.card>
        </div>
      </.scroll_area>

      <div class="h-[calc(100vh-64px)] w-[400px] flex flex-none flex-col border-l border-border">
        <div class="flex flex-none items-center justify-between border-b border-border bg-card/50 p-4 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div class="flex justify-between items-center w-full">
            <h2 class="text-lg font-semibold">
              Contributor chat
            </h2>
            <div class="relative flex -space-x-2">
              <%= for user <- @exclusives do %>
                <.avatar>
                  <.avatar_image src={user.avatar_url} alt="Developer avatar" />
                  <.avatar_fallback>
                    {Algora.Util.initials(@bounty.owner.name)}
                  </.avatar_fallback>
                </.avatar>
              <% end %>
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

                    <div>
                      <.label>Recipient</.label>
                      <.dropdown id="context-dropdown" class="mt-2">
                        <:img :if={@selected_context} src={@selected_context.avatar_url} />
                        <:title :if={@selected_context}>{@selected_context.name}</:title>
                        <:subtitle :if={@selected_context}>@{@selected_context.handle}</:subtitle>

                        <:link :for={context <- @contexts} patch={"?context=#{context.id}"}>
                          <div class="flex items-center whitespace-nowrap">
                            <img
                              src={context.avatar_url}
                              alt={context.name}
                              class="mr-3 h-10 w-10 rounded-full"
                            />
                            <div>
                              <div class="font-semibold">{context.name}</div>
                              <div class="text-sm text-gray-500">@{context.handle}</div>
                            </div>
                          </div>
                        </:link>
                      </.dropdown>
                    </div>

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
      class="size-8 relative cursor-pointer text-foreground/90 hover:text-foreground bg-muted"
    >
      <.icon
        id={@id <> "-copy-icon"}
        name={@icon}
        class="absolute inset-0 m-auto size-5 flex items-center justify-center"
      />
      <.icon
        id={@id <> "-check-icon"}
        name="tabler-check"
        class="absolute inset-0 m-auto hidden size-5 flex items-center justify-center"
      />
    </.button>
    """
  end

  defp contexts(_bounty) do
    Accounts.list_featured_developers()
  end

  defp close_drawers(socket) do
    socket
    |> assign(:show_reward_modal, false)
    |> assign(:show_exclusive_modal, false)
  end

  defp assign_exclusives(socket, shared_with) do
    exclusives =
      Enum.flat_map(shared_with, fn provider_id ->
        with {:ok, token} <- Accounts.get_access_token(socket.assigns.current_user),
             {:ok, user} <- Workspace.ensure_user_by_provider_id(token, provider_id) do
          [user]
        else
          _ -> []
        end
      end)

    assign(socket, :exclusives, exclusives)
  end
end
