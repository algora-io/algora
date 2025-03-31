defmodule AlgoraWeb.BountyLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Changeset

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.LineItem
  alias Algora.Repo

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

  @impl true
  def mount(%{"id" => bounty_id}, _session, socket) do
    bounty =
      Bounty
      |> Repo.get!(bounty_id)
      |> Repo.preload([
        :owner,
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

    changeset =
      RewardBountyForm.changeset(%RewardBountyForm{}, %{
        tip_percentage: 0,
        amount: Money.to_decimal(bounty.amount)
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
     |> assign(:selected_context, nil)
     |> assign(:line_items, [])
     |> assign(:reward_form, to_form(changeset))}
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

  def handle_event("close_drawer", _params, socket) do
    {:noreply, assign(socket, :show_reward_modal, false)}
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

  defp assign_selected_context(socket, context_id) do
    case Enum.find(socket.assigns.contexts, &(&1.id == context_id)) do
      nil ->
        socket

      context ->
        assign(socket, :selected_context, context)
    end
  end

  defp assign_line_items(socket) do
    line_items =
      Bounties.generate_line_items(
        %{amount: calculate_final_amount(socket.assigns.reward_form.source)},
        ticket_ref: ticket_ref(socket),
        recipient: socket.assigns.selected_context
      )

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
    <div class="container mx-auto py-8 px-4">
      <div class="grid gap-8 md:grid-cols-[2fr_1fr]">
        <div class="space-y-8">
          <.card>
            <.card_header>
              <div class="flex items-center gap-4">
                <.avatar class="h-12 w-12 rounded-full">
                  <.avatar_image src={@ticket.repository.user.avatar_url} />
                  <.avatar_fallback>
                    {String.first(@ticket.repository.user.provider_login)}
                  </.avatar_fallback>
                </.avatar>
                <div>
                  <.link
                    href={@ticket.url}
                    class="text-xl font-semibold hover:underline"
                    target="_blank"
                  >
                    {@ticket.title}
                  </.link>
                  <div class="text-sm text-muted-foreground">
                    {@ticket.repository.user.provider_login}/{@ticket.repository.name}#{@ticket.number}
                  </div>
                </div>
              </div>
            </.card_header>
            <.card_content>
              <div class="prose dark:prose-invert">
                {Phoenix.HTML.raw(@ticket_body_html)}
              </div>
            </.card_content>
          </.card>
        </div>

        <div class="space-y-8">
          <.card>
            <.card_header>
              <div class="flex items-center justify-between">
                <.card_title>
                  Bounty
                </.card_title>
                <.button phx-click="reward">
                  Reward
                </.button>
              </div>
            </.card_header>
            <.card_content>
              <div class="space-y-2">
                <div class="flex justify-between text-sm">
                  <span class="text-muted-foreground">Frequency</span>
                  <span class="font-medium font-display tabular-nums">
                    {bounty_frequency(@bounty)}
                  </span>
                </div>
                <div class="flex justify-between text-sm">
                  <span class="text-muted-foreground">Amount</span>
                  <span class="font-medium font-display tabular-nums">
                    {Money.to_string!(@bounty.amount)}
                  </span>
                </div>
                <div class="flex justify-between text-sm">
                  <span class="text-muted-foreground">Total paid</span>
                  <span class="font-medium font-display tabular-nums">
                    {Money.to_string!(@total_paid)}
                  </span>
                </div>
              </div>
            </.card_content>
          </.card>

          <.card>
            <.card_header>
              <div class="flex items-center justify-between">
                <.card_title>
                  Shared with
                </.card_title>
                <.button phx-click="invite">
                  Invite
                </.button>
              </div>
            </.card_header>
            <.card_content>
              <div class="space-y-4">
                <div class="flex justify-between text-sm">
                  <span>
                    <div class="flex items-center gap-4">
                      <.avatar>
                        <.avatar_image src={@bounty.owner.avatar_url} />
                        <.avatar_fallback>{String.first(@bounty.owner.name)}</.avatar_fallback>
                      </.avatar>
                      <div>
                        <p class="font-medium">{@bounty.owner.name} Contributors</p>
                        <p class="text-sm text-muted-foreground">
                          <% names =
                            org_contributors(@bounty)
                            |> Enum.map(&"@#{&1.handle}") %>
                          {if length(names) > 3,
                            do: "#{names |> Enum.take(3) |> Enum.join(", ")} and more",
                            else: "#{names |> Algora.Util.format_name_list()}"}
                        </p>
                      </div>
                    </div>
                  </span>
                </div>
                <%= for user <- shared_users(@bounty) do %>
                  <div class="flex justify-between text-sm">
                    <span>
                      <div class="flex items-center gap-4">
                        <.avatar>
                          <.avatar_image src={user.avatar_url} />
                          <.avatar_fallback>{String.first(user.name)}</.avatar_fallback>
                        </.avatar>
                        <div>
                          <p class="font-medium">{user.name}</p>
                          <p class="text-sm text-muted-foreground">@{User.handle(user)}</p>
                        </div>
                      </div>
                    </span>
                  </div>
                <% end %>
                <%= for user <- invited_users(@bounty) do %>
                  <div class="flex justify-between text-sm">
                    <span>
                      <div class="flex items-center gap-4">
                        <.icon name="tabler-mail" class="h-10 w-10 text-muted-foreground" />
                        <div>
                          <p class="font-medium">{user}</p>
                        </div>
                      </div>
                    </span>
                  </div>
                <% end %>
              </div>
            </.card_content>
          </.card>
        </div>
      </div>
    </div>

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

  # TODO: implement this
  defp shared_users(_bounty) do
    Enum.drop(Accounts.list_featured_developers(), 3)
  end

  # TODO: implement this
  defp invited_users(_bounty) do
    ["alice@example.com", "bob@example.com"]
  end

  # TODO: implement this
  defp org_contributors(_bounty) do
    Enum.take(Accounts.list_featured_developers(), 3)
  end

  defp contexts(_bounty) do
    Accounts.list_featured_developers()
  end

  # TODO: implement this
  defp bounty_frequency(_bounty) do
    "Monthly"
  end
end
