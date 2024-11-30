defmodule AlgoraWeb.Contract.Modals.ReleaseDrawer do
  use AlgoraWeb.LiveComponent

  import Ecto.Query
  import Ecto.Changeset

  alias Algora.{Contracts, MoneyUtils, Repo, Util, Users.User}
  alias Algora.Payments.Transaction

  attr :show, :boolean, required: true
  attr :on_cancel, :string, required: true
  attr :contract, :map, required: true
  attr :timesheet, :map, required: true
  attr :escrow_amount, :map, required: true

  def render(assigns) do
    ~H"""
    <div>
      <.drawer show={@show} on_cancel={@on_cancel}>
        <.drawer_header>
          <h3 class="text-lg font-semibold">Release Payment</h3>
        </.drawer_header>
        <.drawer_content>
          <div class="grid grid-cols-2 gap-8">
            <form phx-submit="release_payment" class="space-y-6">
              <.form_item>
                <.form_label>Feedback for <%= @contract.provider.name %></.form_label>
                <.form_control>
                  <.input
                    type="textarea"
                    rows={8}
                    name="feedback"
                    value=""
                    placeholder="Share your experience working with the developer..."
                    required
                  />
                </.form_control>
                <.form_description>
                  Your feedback helps other companies make informed decisions.
                </.form_description>
              </.form_item>
            </form>

            <div class="flex flex-col gap-8">
              <.card>
                <.card_header>
                  <.card_title>Past Escrow Release</.card_title>
                </.card_header>
                <.card_content>
                  <dl class="space-y-4">
                    <div class="flex justify-between">
                      <dt class="text-muted-foreground">
                        Payout amount (<%= @timesheet.hours_worked %> hours x <%= Money.to_string!(
                          @contract.hourly_rate
                        ) %>/hr)
                      </dt>
                      <dd class="font-semibold font-display tabular-nums">
                        <%= Money.to_string!(Contracts.calculate_amount(@contract, @timesheet)) %>
                      </dd>
                    </div>
                    <div class="flex justify-between">
                      <dt class="text-muted-foreground">
                        Escrow balance
                      </dt>
                      <dd class="font-semibold font-display tabular-nums">
                        -<%= Money.to_string!(@escrow_amount) %>
                      </dd>
                    </div>
                    <div class="h-px bg-border" />
                    <div class="flex justify-between">
                      <dt class="font-medium">Total Due</dt>
                      <dd class="font-semibold font-display tabular-nums">
                        <%= Money.to_string!(
                          Money.sub!(
                            Contracts.calculate_amount(@contract, @timesheet),
                            @escrow_amount
                          )
                        ) %>
                      </dd>
                    </div>
                  </dl>
                </.card_content>
              </.card>

              <div class="mt-auto flex gap-4 justify-end">
                <.button variant="outline" type="button" on_cancel="close_drawer">
                  Cancel
                </.button>
                <.button phx-click="release" phx-target={@myself} type="submit">
                  <.icon name="tabler-check" class="w-4 h-4 mr-2" /> Confirm Release
                </.button>
              </div>
            </div>
          </div>
        </.drawer_content>
      </.drawer>
    </div>
    """
  end

  @impl true
  def handle_event("release", _params, socket) do
    %{contract: contract, timesheet: timesheet, escrow_amount: escrow_amount, fee_data: fee_data} =
      socket.assigns

    org =
      from(u in User,
        where: u.handle == ^contract.client.handle,
        preload: [customer: :default_payment_method]
      )
      |> Repo.one!()

    # Previous period's remaining balance (hours worked minus escrow)
    previous_period_balance =
      Money.sub!(Contracts.calculate_amount(contract, timesheet), escrow_amount)

    # Final amount including platform fees
    grand_total = Money.mult!(previous_period_balance, Decimal.add(1, fee_data.total_fee))

    if Money.positive?(grand_total) do
      transaction =
        Repo.insert!(%Transaction{
          id: Nanoid.generate(),
          amount: grand_total,
          provider: "stripe",
          provider_id: nil,
          provider_meta: nil,
          type: :charge,
          status: :pending,
          succeeded_at: nil,
          contract_id: contract.id,
          original_contract_id: contract.original_contract_id
        })

      case Stripe.PaymentIntent.create(%{
             amount: MoneyUtils.to_minor_units(grand_total),
             currency: to_string(grand_total.currency),
             customer: org.customer.provider_id,
             payment_method: org.customer.default_payment_method.provider_id,
             off_session: true,
             confirm: true
           }) do
        {:ok, ch} ->
          transaction
          |> change(%{
            provider_id: ch.id,
            provider_meta: Util.normalize_struct(ch),
            status: if(ch.status == "succeeded", do: :succeeded, else: :processing),
            succeeded_at: if(ch.status == "succeeded", do: DateTime.utc_now(), else: nil)
          })
          |> Repo.update!()

        {:error, error} ->
          transaction
          |> change(%{
            status: :failed,
            provider_meta: %{error: error}
          })
          |> Repo.update!()

          {:error, error}
      end
    end

    {:noreply, socket}
  end
end
