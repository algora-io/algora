defmodule AlgoraWeb.ClaimLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Bounties.Claim
  alias Algora.Bounties.LineItem
  alias Algora.Organizations
  alias Algora.Repo
  alias Algora.Util

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
      |> validate_required([:amount, :tip_percentage])
      |> validate_number(:tip_percentage, greater_than_or_equal_to: 0)
      |> validate_number(:amount, greater_than: 0)
    end
  end

  @impl true
  def mount(%{"group_id" => group_id}, _session, socket) do
    claims =
      from(c in Claim, where: c.group_id == ^group_id)
      |> order_by(desc: :group_share)
      |> Repo.all()
      |> Repo.preload([
        :user,
        :transactions,
        source: [repository: [:user]],
        target: [repository: [:user], bounties: [:owner]]
      ])

    case claims do
      [] ->
        raise(AlgoraWeb.NotFoundError)

      [primary_claim | _] ->
        prize_pool =
          primary_claim.target.bounties
          |> Enum.map(& &1.amount)
          |> Enum.reduce(Money.zero(:USD, no_fraction_if_integer: true), &Money.add!(&1, &2))

        debits =
          claims
          |> Enum.flat_map(& &1.transactions)
          |> Enum.filter(&(&1.type == :debit and &1.status == :succeeded))

        total_paid =
          debits
          |> Enum.map(& &1.net_amount)
          |> Enum.reduce(Money.zero(:USD, no_fraction_if_integer: true), &Money.add!(&1, &2))

        source_body_html = Algora.Markdown.render(if primary_claim.source, do: primary_claim.source.description)

        pledges =
          primary_claim.target.bounties
          |> Enum.group_by(& &1.owner.id)
          |> Map.new(fn {owner_id, bounties} ->
            {owner_id,
             {hd(bounties).owner,
              Enum.reduce(bounties, Money.zero(:USD, no_fraction_if_integer: true), &Money.add!(&1.amount, &2))}}
          end)

        payments =
          debits
          |> Enum.group_by(& &1.user_id)
          |> Map.new(fn {user_id, debits} ->
            {user_id, Enum.reduce(debits, Money.zero(:USD, no_fraction_if_integer: true), &Money.add!(&1.net_amount, &2))}
          end)

        sponsors =
          pledges
          |> Enum.map(fn {sponsor_id, {sponsor, pledged}} ->
            paid = Map.get(payments, sponsor_id, Money.zero(:USD, no_fraction_if_integer: true))
            tipped = Money.sub!(paid, pledged)

            status =
              cond do
                Money.equal?(paid, pledged) -> :paid
                Money.positive?(tipped) -> :overpaid
                Money.positive?(paid) -> :partial
                primary_claim.status == :approved -> :pending
                true -> :none
              end

            %{
              sponsor: sponsor,
              status: status,
              pledged: pledged,
              paid: paid,
              tipped: tipped
            }
          end)
          |> Enum.sort_by(&{&1.pledged, &1.paid, &1.sponsor.name}, :desc)

        source_or_target = primary_claim.source || primary_claim.target

        contexts =
          if socket.assigns.current_user do
            Organizations.get_user_orgs(socket.assigns.current_user) ++ [socket.assigns.current_user]
          else
            []
          end

        context_ids = MapSet.new(contexts, & &1.id)
        available_bounties = Enum.filter(primary_claim.target.bounties, &MapSet.member?(context_ids, &1.owner_id))

        amount =
          case available_bounties do
            [] -> nil
            [bounty | _] -> Money.to_decimal(bounty.amount)
          end

        changeset = RewardBountyForm.changeset(%RewardBountyForm{}, %{tip_percentage: 0, amount: amount})

        {:ok,
         socket
         |> assign(:page_title, source_or_target.title)
         |> assign(:claims, claims)
         |> assign(:primary_claim, primary_claim)
         |> assign(:target, primary_claim.target)
         |> assign(:source, primary_claim.source)
         |> assign(:source_or_target, source_or_target)
         |> assign(:bounties, primary_claim.target.bounties)
         |> assign(:prize_pool, prize_pool)
         |> assign(:total_paid, total_paid)
         |> assign(:source_body_html, source_body_html)
         |> assign(:sponsors, sponsors)
         |> assign(:contexts, contexts)
         |> assign(:show_reward_bounty_modal, false)
         |> assign(:available_bounties, available_bounties)
         |> assign(:reward_bounty_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_params(_params, _url, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_params(%{"context" => context_id}, _url, socket) do
    {:noreply, socket |> assign_selected_context(context_id) |> assign_line_items()}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket |> assign_selected_context(default_context_id(socket)) |> assign_line_items()}
  end

  @impl true
  def handle_event("reward_bounty", _params, %{assigns: %{current_user: nil}} = socket) do
    {:noreply,
     redirect(socket, to: ~p"/auth/login?#{%{return_to: ~p"/claims/#{socket.assigns.primary_claim.group_id}"}}")}
  end

  def handle_event("reward_bounty", _params, socket) do
    {:noreply, assign(socket, :show_reward_bounty_modal, true)}
  end

  def handle_event("close_drawer", _params, socket) do
    {:noreply, assign(socket, :show_reward_bounty_modal, false)}
  end

  def handle_event("validate_reward_bounty", %{"reward_bounty_form" => params}, socket) do
    {:noreply,
     socket
     |> assign(:reward_bounty_form, to_form(RewardBountyForm.changeset(%RewardBountyForm{}, params)))
     |> assign_line_items()}
  end

  def handle_event("pay_with_stripe", %{"reward_bounty_form" => params}, socket) do
    changeset = RewardBountyForm.changeset(%RewardBountyForm{}, params)

    case apply_action(changeset, :save) do
      {:ok, data} ->
        with {:ok, bounty} <- get_or_create_bounty(socket, data),
             {:ok, session_url} <- reward_bounty(socket, bounty, changeset) do
          {:noreply, redirect(socket, external: session_url)}
        else
          {:error, reason} ->
            Logger.error("Failed to create payment session: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Something went wrong")}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, :reward_bounty_form, to_form(changeset))}
    end
  end

  defp default_context_id(socket) do
    case socket.assigns.available_bounties do
      [] -> socket.assigns.current_user.id
      [bounty | _] -> bounty.owner_id
    end
  end

  defp assign_selected_context(socket, context_id) do
    case Enum.find(socket.assigns.contexts, &(&1.id == context_id)) do
      nil ->
        push_patch(socket, to: "/claims/#{socket.assigns.primary_claim.group_id}?context=#{default_context_id(socket)}")

      context ->
        assign(socket, :selected_context, context)
    end
  end

  defp assign_line_items(socket) do
    line_items =
      Bounties.generate_line_items(%{amount: calculate_final_amount(socket.assigns.reward_bounty_form.source)},
        ticket_ref: ticket_ref(socket),
        claims: socket.assigns.claims
      )

    assign(socket, :line_items, line_items)
  end

  defp ticket_ref(socket) do
    if socket.assigns.target.repository do
      %{
        owner: socket.assigns.target.repository.user.provider_login,
        repo: socket.assigns.target.repository.name,
        number: socket.assigns.target.number
      }
    end
  end

  defp get_or_create_bounty(socket, data) do
    case Enum.find(socket.assigns.available_bounties, &(&1.owner_id == socket.assigns.selected_context.id)) do
      nil ->
        Bounties.create_bounty(%{
          creator: socket.assigns.current_user,
          owner: socket.assigns.selected_context,
          amount: Money.new!(:USD, data.amount),
          ticket_ref: ticket_ref(socket)
        })

      bounty ->
        {:ok, bounty}
    end
  end

  defp reward_bounty(socket, bounty, changeset) do
    final_amount = calculate_final_amount(changeset)

    Bounties.reward_bounty(
      %{
        owner: socket.assigns.selected_context,
        amount: final_amount,
        bounty_id: bounty.id,
        claims: socket.assigns.claims
      },
      ticket_ref: ticket_ref(socket)
    )
  end

  defp calculate_final_amount(changeset) do
    tip_percentage = get_field(changeset, :tip_percentage) || Decimal.new(0)
    amount = get_field(changeset, :amount) || Decimal.new(0)

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
                <.avatar :if={@source_or_target.repository} class="h-12 w-12 rounded-full">
                  <.avatar_image src={@source_or_target.repository.user.avatar_url} />
                  <.avatar_fallback>
                    {Algora.Util.initials(@source_or_target.repository.user.provider_login)}
                  </.avatar_fallback>
                </.avatar>
                <div>
                  <.link
                    href={@source_or_target.url}
                    class="text-xl font-semibold hover:underline"
                    target="_blank"
                  >
                    {@source_or_target.title}
                  </.link>
                  <div :if={@source_or_target.repository} class="text-sm text-muted-foreground">
                    {@source_or_target.repository.user.provider_login}/{@source_or_target.repository.name}#{@source_or_target.number}
                  </div>
                  <.link
                    :if={!@source_or_target.repository}
                    href={@primary_claim.url}
                    rel="noopener"
                    class="block text-sm text-muted-foreground"
                  >
                    {@primary_claim.url}
                  </.link>
                </div>
              </div>
            </.card_header>
            <.card_content>
              <div class="prose dark:prose-invert">
                {Phoenix.HTML.raw(@source_body_html)}
              </div>
            </.card_content>
          </.card>
        </div>

        <div class="space-y-8">
          <.card>
            <.card_header>
              <div class="flex items-center justify-between">
                <.card_title>
                  Claim
                </.card_title>
                <.button phx-click="reward_bounty">
                  Reward bounty
                </.button>
              </div>
            </.card_header>
            <.card_content>
              <div class="space-y-2">
                <div class="flex justify-between text-sm">
                  <span class="text-muted-foreground">Total prize pool</span>
                  <span class="font-medium font-display tabular-nums">
                    {Money.to_string!(@prize_pool)}
                  </span>
                </div>
                <div class="flex justify-between text-sm">
                  <span class="text-muted-foreground">Total paid</span>
                  <span class="font-medium font-display tabular-nums">
                    {Money.to_string!(@total_paid)}
                  </span>
                </div>
                <div class="flex justify-between text-sm">
                  <span class="text-muted-foreground">Status</span>
                  <span>{@primary_claim.status |> to_string() |> String.capitalize()}</span>
                </div>
                <div class="flex justify-between text-sm">
                  <span class="text-muted-foreground">Submitted</span>
                  <span>{Calendar.strftime(@primary_claim.inserted_at, "%B %d, %Y")}</span>
                </div>
                <div class="flex justify-between text-sm">
                  <span class="text-muted-foreground">Last updated</span>
                  <span>{Calendar.strftime(@primary_claim.updated_at, "%B %d, %Y")}</span>
                </div>
              </div>
            </.card_content>
          </.card>

          <.card>
            <.card_header>
              <div class="flex items-center justify-between">
                <.card_title>
                  Authors
                </.card_title>
              </div>
            </.card_header>
            <.card_content>
              <div class="space-y-4">
                <%= for claim <- @claims do %>
                  <div class="flex justify-between text-sm">
                    <span>
                      <div class="flex items-center gap-4">
                        <.avatar>
                          <.avatar_image src={claim.user.avatar_url} />
                          <.avatar_fallback>{Algora.Util.initials(claim.user.name)}</.avatar_fallback>
                        </.avatar>
                        <div>
                          <p class="font-medium">{claim.user.name}</p>
                          <p class="text-sm text-muted-foreground">@{User.handle(claim.user)}</p>
                        </div>
                      </div>
                    </span>
                    <span class="text-foreground font-medium">
                      <span>
                        {Util.format_pct(claim.group_share)}
                      </span>
                    </span>
                  </div>
                <% end %>
              </div>
            </.card_content>
          </.card>

          <.card>
            <.card_header>
              <.card_title>
                Sponsors
              </.card_title>
            </.card_header>
            <.card_content>
              <div class="divide-y divide-border">
                <%= for sponsor <- @sponsors do %>
                  <div class="flex items-center justify-between py-4">
                    <div class="flex items-center gap-4">
                      <.avatar>
                        <.avatar_image src={sponsor.sponsor.avatar_url} />
                        <.avatar_fallback>
                          {Algora.Util.initials(sponsor.sponsor.name)}
                        </.avatar_fallback>
                      </.avatar>
                      <div>
                        <p class="font-medium">{sponsor.sponsor.name}</p>
                        <p class="text-sm text-muted-foreground">@{User.handle(sponsor.sponsor)}</p>
                      </div>
                    </div>
                    <div class="text-right">
                      <div class="text-sm">
                        <%= case sponsor.status do %>
                          <% :overpaid -> %>
                            <div class="text-foreground">
                              <span class="font-semibold font-display tabular-nums">
                                {Money.to_string!(Money.sub!(sponsor.paid, sponsor.tipped))}
                              </span>
                              paid
                            </div>
                            <div class="text-foreground">
                              <span class="font-semibold font-display tabular-nums">
                                +{Money.to_string!(sponsor.tipped)}
                              </span>
                              tip!
                            </div>
                          <% :paid -> %>
                            <div class="text-foreground">
                              <span class="font-semibold font-display tabular-nums">
                                {Money.to_string!(sponsor.paid)}
                              </span>
                              paid
                            </div>
                          <% :partial -> %>
                            <div class="text-foreground">
                              <span class="font-semibold font-display tabular-nums">
                                {Money.to_string!(sponsor.paid)}
                              </span>
                              paid
                            </div>
                            <div class="text-muted-foreground">
                              <span class="font-semibold font-display tabular-nums">
                                {Money.to_string!(Money.sub!(sponsor.pledged, sponsor.paid))}
                              </span>
                              pending
                            </div>
                          <% :pending -> %>
                            <div class="text-muted-foreground">
                              <span class="font-semibold font-display tabular-nums">
                                {Money.to_string!(sponsor.pledged)}
                              </span>
                              pending
                            </div>
                          <% :none -> %>
                            <div class="text-foreground">
                              <span class="font-semibold font-display tabular-nums">
                                {Money.to_string!(sponsor.pledged)}
                              </span>
                            </div>
                        <% end %>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </.card_content>
          </.card>
        </div>
      </div>
    </div>
    <.drawer :if={@current_user} show={@show_reward_bounty_modal} on_cancel="close_drawer">
      <.drawer_header>
        <.drawer_title>Reward Bounty</.drawer_title>
        <.drawer_description>
          You can pay the full bounty now or start with a partial amount - it's up to you!
        </.drawer_description>
      </.drawer_header>
      <.drawer_content class="mt-4">
        <.form
          for={@reward_bounty_form}
          phx-change="validate_reward_bounty"
          phx-submit="pay_with_stripe"
        >
          <div class="flex flex-col gap-8">
            <div class="grid grid-cols-2 gap-8">
              <.card>
                <.card_header>
                  <.card_title>Payment Details</.card_title>
                </.card_header>
                <.card_content>
                  <div class="space-y-4">
                    <%= if Enum.empty?(@available_bounties) do %>
                    <% end %>
                    <.input
                      label="Amount"
                      icon="tabler-currency-dollar"
                      field={@reward_bounty_form[:amount]}
                    />

                    <div>
                      <.label>On behalf of</.label>
                      <.dropdown id="context-dropdown" class="mt-2" border>
                        <:img src={@selected_context.avatar_url} />
                        <:title>{@selected_context.name}</:title>
                        <:subtitle>@{@selected_context.handle}</:subtitle>

                        <:link
                          :for={context <- @contexts |> Enum.reject(&(&1.id == @selected_context.id))}
                          patch={"?context=#{context.id}"}
                        >
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
                          field={@reward_bounty_form[:tip_percentage]}
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
end
