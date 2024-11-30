defmodule AlgoraWeb.Contract.Modals.ReleaseDrawer do
  use AlgoraWeb.LiveComponent

  alias Algora.{Contracts, Util}

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
                <.button type="submit" form="release-payment-form">
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
end
