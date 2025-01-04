defmodule AlgoraWeb.User.TransactionsLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  alias Algora.Accounts.User
  alias Algora.Payments
  alias Algora.Stripe.ConnectCountries
  alias Algora.Util

  defmodule PayoutAccountForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @countries ConnectCountries.list()

    embedded_schema do
      field :country, :string
    end

    def changeset(schema \\ %__MODULE__{}, attrs) do
      schema
      |> cast(attrs, [:country])
      |> validate_required([:country])
      |> validate_inclusion(:country, Enum.map(@countries, &elem(&1, 1)))
    end

    def countries, do: @countries
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Payments.subscribe()
    end

    {:ok,
     socket
     |> assign(:page_title, "Your transactions")
     |> assign(:show_payout_drawer, true)
     |> assign(:payout_account_form, to_form(PayoutAccountForm.changeset(%PayoutAccountForm{}, %{})))
     |> assign_transactions()}
  end

  def handle_info(:payments_updated, socket) do
    {:noreply, assign_transactions(socket)}
  end

  def handle_event("show_payout_drawer", _params, socket) do
    {:noreply, assign(socket, :show_payout_drawer, true)}
  end

  def handle_event("close_drawer", _params, socket) do
    {:noreply, assign(socket, :show_payout_drawer, false)}
  end

  def handle_event("create_payout_account", %{"payout_account_form" => params}, socket) do
    changeset =
      %PayoutAccountForm{}
      |> PayoutAccountForm.changeset(params)
      |> Map.put(:action, :validate)

    case changeset do
      %{valid?: true} = changeset ->
        # Get or create Stripe account
        account = Payments.get_account(socket.assigns.current_user.id, :US)

        result =
          if is_nil(account) do
            Payments.create_account(socket.assigns.current_user, %{
              country: changeset.changes.country,
              type: "express"
            })
          else
            {:ok, account}
          end

        case result do
          {:ok, account} ->
            if account.charges_enabled do
              if account.type == :express do
                {:ok, %{url: url}} = Payments.create_login_link(account)

                {:noreply, redirect(socket, external: url)}
              else
                {:noreply,
                 socket
                 |> put_flash(:info, "Account already set up!")
                 |> assign(:show_payout_drawer, false)}
              end
            else
              {:ok, %{url: url}} = Payments.create_account_link(account, AlgoraWeb.Endpoint.url())

              {:noreply, redirect(socket, external: url)}
            end

          {:error, _reason} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to create payout account")
             |> assign(:show_payout_drawer, false)}
        end

      %{valid?: false} = changeset ->
        {:noreply, assign(socket, :payout_account_form, to_form(changeset))}
    end
  end

  defp assign_transactions(socket) do
    transactions =
      Payments.list_transactions(
        user_id: socket.assigns.current_user.id,
        # TODO: also list transactions that are "processing"
        status: :succeeded
      )

    balance = calculate_balance(transactions)
    volume = calculate_volume(transactions)

    socket
    |> assign(:transactions, transactions)
    |> assign(:total_balance, balance)
    |> assign(:total_volume, volume)
  end

  defp calculate_balance(transactions) do
    Enum.reduce(transactions, Money.new!(0, :USD), fn transaction, acc ->
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
    Enum.reduce(transactions, Money.new!(0, :USD), fn transaction, acc ->
      case transaction.type do
        type when type in [:charge, :credit] -> Money.add!(acc, transaction.net_amount)
        _ -> acc
      end
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6">
      <div class="flex items-end justify-between gap-4">
        <div class="space-y-1">
          <h1 class="text-2xl font-bold">Your Transactions</h1>
          <p class="text-muted-foreground">View and manage your transaction history</p>
        </div>
        <.button phx-click="show_payout_drawer">
          <.icon name="tabler-plus" class="w-4 h-4 mr-2 -ml-1" />
          <span>Create payout account</span>
        </.button>
      </div>
      
    <!-- Totals Cards -->
      <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
        <.card>
          <.card_header>
            <.card_title>Lifetime Volume</.card_title>
            <.card_description>Total volume of your transactions</.card_description>
          </.card_header>
          <.card_content>
            <span class="font-display text-2xl font-bold">{Money.to_string!(@total_volume)}</span>
          </.card_content>
        </.card>
        <.card>
          <.card_header>
            <.card_title>Total Balance</.card_title>
            <.card_description>Net balance across all transactions</.card_description>
          </.card_header>
          <.card_content>
            <span class="font-display text-2xl font-bold">{Money.to_string!(@total_balance)}</span>
          </.card_content>
        </.card>
      </div>
      
    <!-- Transactions Table -->
      <.card>
        <.card_header>
          <.card_title>Transaction History</.card_title>
        </.card_header>
        <.card_content>
          <div class="-mx-6 overflow-x-auto">
            <div class="inline-block min-w-full py-2 align-middle">
              <table class="min-w-full divide-y divide-border">
                <thead>
                  <tr>
                    <th scope="col" class="px-6 py-3.5 text-left text-sm font-semibold">Date</th>
                    <th scope="col" class="px-6 py-3.5 text-left text-sm font-semibold">
                      Description
                    </th>
                    <th scope="col" class="px-6 py-3.5 text-left text-sm font-semibold">
                      <div class="flex items-center gap-3">
                        <span class="w-8"></span> Contact
                      </div>
                    </th>
                    <th scope="col" class="px-6 py-3.5 text-right text-sm font-semibold">Amount</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-border">
                  <%= for transaction <- @transactions do %>
                    <tr class="hover:bg-muted/50">
                      <td class="whitespace-nowrap px-6 py-4 text-sm">
                        {Util.timestamp(transaction.inserted_at, @current_user.timezone)}
                      </td>
                      <td class="whitespace-nowrap px-6 py-4 text-sm">
                        {description(transaction)}
                      </td>
                      <td class="whitespace-nowrap px-6 py-4 text-sm">
                        <%= if linked_user = get_linked_user(transaction) do %>
                          <div class="flex items-center gap-3">
                            <.avatar class="h-8 w-8">
                              <.avatar_image src={linked_user.avatar_url} alt={linked_user.name} />
                              <.avatar_fallback>{String.first(linked_user.name)}</.avatar_fallback>
                            </.avatar>
                            <div class="font-medium">
                              <div>{linked_user.name}</div>
                              <div class="text-sm text-muted-foreground">
                                @{User.handle(linked_user)}
                              </div>
                            </div>
                          </div>
                        <% end %>
                      </td>
                      <td class="font-display whitespace-nowrap px-6 py-4 text-right font-medium tabular-nums">
                        <%= case transaction_direction(transaction.type) do %>
                          <% :plus -> %>
                            <span class="text-emerald-400">
                              {Money.to_string!(transaction.net_amount)}
                            </span>
                          <% :minus -> %>
                            <span class="text-red-400">
                              -{Money.to_string!(transaction.net_amount)}
                            </span>
                        <% end %>
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
    <.drawer show={@show_payout_drawer} on_cancel="close_drawer" direction="right">
      <.drawer_header>
        <.drawer_title>Payout Account</.drawer_title>
        <.drawer_description>Create a payout account to receive your earnings</.drawer_description>
      </.drawer_header>
      <.drawer_content class="mt-4">
        <.simple_form for={@payout_account_form} phx-submit="create_payout_account">
          <div class="space-y-6 max-w-md">
            <.input
              field={@payout_account_form[:country]}
              label="Country"
              type="select"
              prompt=""
              options={
                PayoutAccountForm.countries()
                |> Enum.map(fn {name, code} ->
                  {Algora.Misc.CountryEmojis.get(code, "🌎") <> " " <> name, code}
                end)
              }
              helptext="Select the country where you or your business will legally operate."
            />
            <div class="flex justify-end gap-4">
              <.button variant="outline" type="button" phx-click="close_drawer">
                Cancel
              </.button>
              <.button type="submit">
                Create Account
              </.button>
            </div>
          </div>
        </.simple_form>
      </.drawer_content>
    </.drawer>
    """
  end

  defp transaction_direction(type) do
    case type do
      t when t in [:charge, :credit, :deposit] -> :plus
      t when t in [:debit, :withdrawal, :transfer] -> :minus
    end
  end

  defp description(%{type: type, tip_id: tip_id}) when type in [:debit, :credit] and not is_nil(tip_id), do: "Tip payment"

  defp description(%{type: type, contract_id: contract_id}) when type in [:debit, :credit] and not is_nil(contract_id),
    do: "Contract payment"

  defp description(%{type: type, bounty_id: bounty_id}) when type in [:debit, :credit] and not is_nil(bounty_id),
    do: "Bounty payment"

  defp description(%{type: type}) when type in [:debit, :credit], do: "Payment"

  defp description(%{type: type}) do
    type |> to_string() |> String.capitalize()
  end

  defp get_linked_user(%{type: type, linked_transaction: %{user: user}}) when type in [:credit, :debit], do: user

  defp get_linked_user(_), do: nil
end
