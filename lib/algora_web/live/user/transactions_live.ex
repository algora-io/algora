defmodule AlgoraWeb.User.TransactionsLive do
  use AlgoraWeb, :live_view
  use LiveSvelte.Components
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.Users
  alias Algora.Util

  def mount(_params, _session, socket) do
    transactions =
      Payments.list_transactions(
        user_id: socket.assigns.current_user.id,
        # TODO: also list transactions that are "processing"
        status: :succeeded
      )

    {:ok,
     socket
     |> assign(:page_title, "Your transactions")
     |> assign(:transactions, transactions)
     |> assign_totals(transactions)}
  end

  defp assign_totals(socket, transactions) do
    balance = calculate_balance(transactions)
    volume = calculate_volume(transactions)

    socket
    |> assign(:total_balance, balance)
    |> assign(:total_volume, volume)
  end

  defp calculate_balance(transactions) do
    transactions
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
    |> Enum.reduce(Money.new!(0, :USD), fn transaction, acc ->
      case transaction.type do
        type when type in [:charge, :credit] -> Money.add!(acc, transaction.net_amount)
        _ -> acc
      end
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="container max-w-7xl mx-auto p-6 space-y-6">
      <div class="space-y-1">
        <h1 class="text-2xl font-bold">Your Transactions</h1>
        <p class="text-muted-foreground">View and manage your transaction history</p>
      </div>
      
    <!-- Totals Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <.card>
          <.card_header>
            <.card_title>Total Balance</.card_title>
            <.card_description>Net balance across all transactions</.card_description>
          </.card_header>
          <.card_content>
            <span class="text-2xl font-bold font-display">{Money.to_string!(@total_balance)}</span>
          </.card_content>
        </.card>

        <.card>
          <.card_header>
            <.card_title>Lifetime Volume</.card_title>
            <.card_description>Total volume of your transactions</.card_description>
          </.card_header>
          <.card_content>
            <span class="text-2xl font-bold font-display">{Money.to_string!(@total_volume)}</span>
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
                                @{linked_user.provider_login}
                              </div>
                            </div>
                          </div>
                        <% end %>
                      </td>
                      <td class="whitespace-nowrap px-6 py-4 font-display font-medium text-right tabular-nums">
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
    """
  end

  defp transaction_direction(type) do
    case type do
      t when t in [:charge, :credit, :deposit] -> :plus
      t when t in [:debit, :withdrawal, :transfer] -> :minus
    end
  end

  defp description(%{type: type, tip_id: tip_id})
       when type in [:debit, :credit] and not is_nil(tip_id),
       do: "Tip payment"

  defp description(%{type: type, contract_id: contract_id})
       when type in [:debit, :credit] and not is_nil(contract_id),
       do: "Contract payment"

  defp description(%{type: type, bounty_id: bounty_id})
       when type in [:debit, :credit] and not is_nil(bounty_id),
       do: "Bounty payment"

  defp description(%{type: type})
       when type in [:debit, :credit],
       do: "Payment"

  defp description(%{type: type}) do
    type |> to_string() |> String.capitalize()
  end

  defp get_linked_user(%{type: type, linked_transaction: %{user: user}})
       when type in [:credit, :debit],
       do: user

  defp get_linked_user(_), do: nil
end
