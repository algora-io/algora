defmodule AlgoraWeb.Org.TransactionsLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import Ecto.Changeset

  alias Algora.Accounts.User
  alias Algora.Payments
  alias Algora.Util

  defmodule PayoutAccountForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @countries Algora.PSP.ConnectCountries.list()

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

    account =
      case Payments.fetch_account(socket.assigns.current_org) do
        {:ok, account} -> account
        {:error, :not_found} -> nil
      end

    {:ok,
     socket
     |> assign(:page_title, "Transactions")
     |> assign(:show_create_payout_drawer, false)
     |> assign(:show_manage_payout_drawer, false)
     |> assign(:show_delete_confirmation, false)
     |> assign(:payout_account_form, to_form(PayoutAccountForm.changeset(%PayoutAccountForm{}, %{})))
     |> assign(:account, account)
     |> assign_transactions()}
  end

  def handle_info(:payments_updated, socket) do
    {:noreply, assign_transactions(socket)}
  end

  def handle_event("show_create_payout_drawer", _params, socket) do
    {:noreply, assign(socket, :show_create_payout_drawer, true)}
  end

  def handle_event("show_manage_payout_drawer", _params, socket) do
    {:noreply, assign(socket, :show_manage_payout_drawer, true)}
  end

  def handle_event("close_drawer", _params, socket) do
    {:noreply, socket |> assign(:show_create_payout_drawer, false) |> assign(:show_manage_payout_drawer, false)}
  end

  def handle_event("view_dashboard", _params, socket) do
    case Payments.create_login_link(socket.assigns.account) do
      {:ok, %{url: url}} -> {:noreply, redirect(socket, external: url)}
      {:error, _reason} -> {:noreply, put_flash(socket, :error, "Something went wrong")}
    end
  end

  def handle_event("setup_payout_account", _params, socket) do
    case Payments.create_account_link(socket.assigns.account, AlgoraWeb.Endpoint.url()) do
      {:ok, %{url: url}} -> {:noreply, redirect(socket, external: url)}
      {:error, _reason} -> {:noreply, put_flash(socket, :error, "Something went wrong")}
    end
  end

  def handle_event("create_payout_account", %{"payout_account_form" => params}, socket) do
    changeset =
      %PayoutAccountForm{}
      |> PayoutAccountForm.changeset(params)
      |> Map.put(:action, :validate)

    country = get_change(changeset, :country)

    if changeset.valid? do
      with {:ok, account} <-
             Payments.fetch_or_create_account(socket.assigns.current_org, country),
           {:ok, %{url: url}} <- Payments.create_account_link(account, AlgoraWeb.Endpoint.url()) do
        {:noreply, redirect(socket, external: url)}
      else
        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Failed to create payout account")}
      end
    else
      {:noreply, assign(socket, :payout_account_form, to_form(changeset))}
    end
  end

  def handle_event("show_delete_confirmation", _params, socket) do
    {:noreply, assign(socket, :show_delete_confirmation, true)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :show_delete_confirmation, false)}
  end

  def handle_event("delete_payout_account", _params, socket) do
    case Payments.delete_account(socket.assigns.account) do
      {:ok, _account} ->
        {:noreply,
         socket
         |> assign(:account, nil)
         |> assign(:show_delete_confirmation, false)
         |> assign(:show_manage_payout_drawer, false)
         |> put_flash(:info, "Payout account deleted successfully")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:show_delete_confirmation, false)
         |> put_flash(:error, "Failed to delete payout account")}
    end
  end

  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp assign_transactions(socket) do
    transactions =
      Payments.list_transactions(
        user_id: socket.assigns.current_org.id,
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
      <div class="space-y-4">
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <div class="space-y-1">
            <h1 class="text-2xl font-bold">Transactions</h1>
            <p class="text-muted-foreground">View and manage your transaction history</p>
          </div>
          <%= if @account do %>
            <.button phx-click="show_manage_payout_drawer">
              Manage payout settings
            </.button>
          <% else %>
            <.button phx-click="show_create_payout_drawer">
              Create payout account
            </.button>
          <% end %>
        </div>
        <%= if @account do %>
          <div class="flex items-center gap-2">
            <%= if @account.payouts_enabled do %>
              <.badge variant="success" phx-click="show_manage_payout_drawer" class="cursor-pointer">
                Payout account active
              </.badge>
            <% else %>
              <.badge variant="warning" phx-click="show_manage_payout_drawer" class="cursor-pointer">
                Payout account setup required
              </.badge>
            <% end %>
          </div>
        <% end %>
      </div>
      
    <!-- Totals Cards -->
      <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
        <.card class="flex justify-between">
          <.card_header>
            <.card_title>Lifetime Volume</.card_title>
            <.card_description>Total volume of your transactions</.card_description>
          </.card_header>
          <.card_content>
            <span class="font-display text-2xl font-bold">{Money.to_string!(@total_volume)}</span>
          </.card_content>
        </.card>
        <.card class="flex justify-between">
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
      <.card :if={length(@transactions) > 0}>
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
                        {Util.timestamp(transaction.inserted_at, @current_org.timezone)}
                      </td>
                      <td class="whitespace-nowrap px-6 py-4 text-sm">
                        {description(transaction)}
                      </td>
                      <td class="whitespace-nowrap px-6 py-4 text-sm">
                        <%= if linked_user = get_linked_user(transaction) do %>
                          <div class="flex items-center gap-3">
                            <.avatar class="h-8 w-8">
                              <.avatar_image src={linked_user.avatar_url} alt={linked_user.name} />
                              <.avatar_fallback>
                                {Algora.Util.initials(linked_user.name)}
                              </.avatar_fallback>
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
    <.drawer show={@show_create_payout_drawer} on_cancel="close_drawer" direction="right">
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
                  {Algora.Misc.CountryEmojis.get(code) <> " " <> name, code}
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
    <.drawer
      :if={@account}
      show={@show_manage_payout_drawer}
      on_cancel="close_drawer"
      direction="right"
    >
      <.drawer_header>
        <.drawer_title>Payout Account</.drawer_title>
        <.drawer_description>Manage your payout account</.drawer_description>
      </.drawer_header>
      <.drawer_content class="mt-4">
        <div class="space-y-6">
          <div class="grid grid-cols-1 gap-6">
            <.card>
              <.card_header>
                <.card_title>Account Status</.card_title>
              </.card_header>
              <.card_content>
                <dl class="grid grid-cols-2 gap-6">
                  <div>
                    <dt class="text-sm font-medium text-muted-foreground">Account Type</dt>
                    <dd class="text-sm font-semibold">
                      {@account.type |> to_string() |> String.capitalize()}
                    </dd>
                  </div>
                  <div>
                    <dt class="text-sm font-medium text-muted-foreground">Country</dt>
                    <dd class="text-sm font-semibold">
                      {Algora.PSP.ConnectCountries.from_code(@account.country)}
                    </dd>
                  </div>
                  <div>
                    <dt class="text-sm font-medium text-muted-foreground">Can Accept Payments</dt>
                    <dd class="text-sm font-semibold">
                      <%= if @account.charges_enabled do %>
                        <div class="text-success text-lg">✓</div>
                      <% else %>
                        <div class="text-destructive text-lg">✗</div>
                      <% end %>
                    </dd>
                  </div>
                  <div>
                    <dt class="text-sm font-medium text-muted-foreground">Can Withdraw Payments</dt>
                    <dd class="text-sm font-semibold">
                      <%= if @account.payouts_enabled do %>
                        <div class="text-success text-lg">✓</div>
                      <% else %>
                        <div class="text-destructive text-lg">✗</div>
                      <% end %>
                    </dd>
                  </div>
                </dl>
              </.card_content>
            </.card>

            <.card :if={@account.details_submitted and @account.provider_meta}>
              <.card_header>
                <.card_title>Payout Settings</.card_title>
              </.card_header>
              <.card_content>
                <dl class="grid grid-cols-2 gap-6">
                  <div :if={@account.payout_interval}>
                    <dt class="text-sm font-medium text-muted-foreground">Payout Interval</dt>
                    <dd class="text-sm font-semibold">
                      {String.capitalize(@account.payout_interval)}
                    </dd>
                  </div>
                  <div :if={@account.payout_speed}>
                    <dt class="text-sm font-medium text-muted-foreground">Payout Speed</dt>
                    <dd class="text-sm font-semibold">
                      {@account.payout_speed} {ngettext("day", "days", @account.payout_speed)}
                    </dd>
                  </div>
                  <div :if={@account.default_currency}>
                    <dt class="text-sm font-medium text-muted-foreground">Payout Currency</dt>
                    <dd class="text-sm font-semibold">
                      {@account.default_currency |> String.upcase()}
                    </dd>
                  </div>
                  <%= if bank_account = Enum.find(get_in(@account.provider_meta, ["external_accounts", "data"]), fn account -> account["default_for_currency"] end) do %>
                    <div>
                      <dt class="text-sm font-medium text-muted-foreground">Bank Account</dt>
                      <dd class="text-sm font-semibold">
                        <div>{bank_account["bank_name"]}</div>
                        <div class="text-muted-foreground">**** {bank_account["last4"]}</div>
                      </dd>
                    </div>
                  <% end %>
                </dl>
              </.card_content>
            </.card>
          </div>

          <div class="flex flex-col-reverse sm:flex-row gap-3">
            <.button class="flex-1" phx-click="show_delete_confirmation" variant="destructive">
              Delete account
            </.button>

            <%= if not @account.details_submitted do %>
              <.button class="flex-1" phx-click="setup_payout_account">
                Continue onboarding
              </.button>
            <% end %>

            <%= if @account.details_submitted and @account.type != :express do %>
              <.button class="flex-1" phx-click="setup_payout_account">
                Update details
              </.button>
            <% end %>

            <%= if @account.details_submitted and @account.type == :express do %>
              <.button class="flex-1" phx-click="setup_payout_account" variant="secondary">
                Update details
              </.button>
              <.button class="flex-1" phx-click="view_dashboard">
                View dashboard
              </.button>
            <% end %>
          </div>
        </div>
      </.drawer_content>
    </.drawer>
    <.dialog
      :if={@show_delete_confirmation}
      id="delete-confirmation-dialog"
      show={@show_delete_confirmation}
      on_cancel={JS.patch(~p"/user/transactions", [])}
    >
      <.dialog_content>
        <.dialog_header>
          <.dialog_title>Delete Payout Account</.dialog_title>
          <.dialog_description>
            Are you sure you want to delete your payout account? This action is irreversible and you will need to create a new account to receive payments.
          </.dialog_description>
        </.dialog_header>
        <.dialog_footer>
          <.button variant="outline" phx-click="cancel_delete">Cancel</.button>
          <.button variant="destructive" phx-click="delete_payout_account">Delete Account</.button>
        </.dialog_footer>
      </.dialog_content>
    </.dialog>
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
