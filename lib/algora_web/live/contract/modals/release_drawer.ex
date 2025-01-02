defmodule AlgoraWeb.Contract.Modals.ReleaseDrawer do
  @moduledoc false
  use AlgoraWeb.LiveComponent

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Contracts
  alias Algora.Contracts.Contract
  alias Algora.MoneyUtils
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Users.User
  alias Algora.Util

  attr :show, :boolean, required: true
  attr :on_cancel, :string, required: true
  attr :contract, :map, required: true

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
                <.form_label>Feedback for {@contract.contractor.name}</.form_label>
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
                        Payout amount ({@contract.timesheet.hours_worked} hours x {MoneyUtils.fmt_precise!(
                          @contract.hourly_rate
                        )}/hr)
                      </dt>
                      <dd class="font-semibold font-display tabular-nums">
                        {MoneyUtils.fmt_precise!(Contracts.calculate_transfer_amount(@contract))}
                      </dd>
                    </div>
                    <div class="flex justify-between">
                      <dt class="text-muted-foreground">
                        Escrow balance
                      </dt>
                      <dd class="font-semibold font-display tabular-nums">
                        -{MoneyUtils.fmt_precise!(Contract.balance(@contract))}
                      </dd>
                    </div>
                    <div class="h-px bg-border" />
                    <div class="flex justify-between">
                      <dt class="font-medium">Total Due</dt>
                      <dd class="font-semibold font-display tabular-nums">
                        {MoneyUtils.fmt_precise!(
                          Money.sub!(
                            Contracts.calculate_transfer_amount(@contract),
                            Contract.balance(@contract)
                          )
                        )}
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
    %{contract: contract, fee_data: fee_data} = socket.assigns

    org =
      Repo.one!(from(u in User, where: u.handle == ^contract.client.handle, preload: [customer: :default_payment_method]))

    net_amount =
      Money.sub!(Contracts.calculate_transfer_amount(contract), Contract.balance(contract))

    total_fee = Money.mult!(net_amount, fee_data.total_fee)
    gross_amount = Money.add!(net_amount, total_fee)

    if Money.positive?(gross_amount) do
      transaction =
        Repo.insert!(%Transaction{
          id: Nanoid.generate(),
          gross_amount: gross_amount,
          net_amount: net_amount,
          total_fee: total_fee,
          provider: "stripe",
          provider_id: nil,
          provider_meta: nil,
          type: :charge,
          status: :initialized,
          succeeded_at: nil,
          contract_id: contract.id,
          original_contract_id: contract.original_contract_id
        })

      case Stripe.PaymentIntent.create(%{
             amount: MoneyUtils.to_minor_units(gross_amount),
             currency: to_string(gross_amount.currency),
             customer: org.customer.provider_id,
             payment_method: org.customer.default_payment_method.provider_id,
             off_session: true,
             confirm: true
           }) do
        {:ok, pi} ->
          transaction
          |> change(%{
            provider_id: pi.id,
            provider_meta: Util.normalize_struct(pi),
            provider_fee: Payments.get_provider_fee(:stripe, pi),
            status: if(pi.status == "succeeded", do: :succeeded, else: :processing),
            succeeded_at: if(pi.status == "succeeded", do: DateTime.utc_now())
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
