defmodule AlgoraWeb.Contract.Modals.DisputeDrawer do
  use AlgoraWeb.LiveComponent

  attr :show, :boolean, required: true
  attr :on_cancel, :string, required: true
  attr :contract, :map, required: true

  def render(assigns) do
    ~H"""
    <div>
      <.drawer show={@show} on_cancel={@on_cancel}>
        <.drawer_header>
          <h3 class="text-lg font-semibold text-destructive">Raise Payment Dispute</h3>
        </.drawer_header>
        <.drawer_content>
          <div class="grid grid-cols-2 gap-8">
            <div>
              <form phx-submit="raise_dispute" class="space-y-6">
                <.form_item>
                  <.form_label>Reason for dispute</.form_label>
                  <.form_control>
                    <.input
                      type="textarea"
                      rows={10}
                      name="reason"
                      value=""
                      placeholder="Please provide detailed information about why you're disputing this payment..."
                      class="min-h-[120px]"
                      required
                    />
                  </.form_control>
                  <.form_description>
                    Be specific about any issues or concerns. This will help resolve the dispute faster.
                  </.form_description>
                </.form_item>

                <.alert variant="destructive" class="mt-4">
                  <.icon name="tabler-alert-triangle" class="w-4 h-4 mr-2" />
                  Disputes should only be raised for serious issues. Our team will review your case within 24 hours.
                </.alert>

                <div class="flex gap-4">
                  <.button variant="outline" type="button" on_cancel="close_drawer">
                    Cancel
                  </.button>
                  <.button variant="destructive" type="submit">
                    <.icon name="tabler-alert-triangle" class="w-4 h-4 mr-2" /> Raise Dispute
                  </.button>
                </div>
              </form>
            </div>

            <div>
              <.card>
                <.card_header>
                  <.card_title>Dispute Information</.card_title>
                </.card_header>
                <.card_content>
                  <dl class="space-y-4">
                    <div class="flex justify-between">
                      <dt class="text-muted-foreground">Disputed Amount</dt>
                      <dd class="font-semibold">
                        {Money.to_string!(@contract.amount_debited)}
                      </dd>
                    </div>
                    <div class="flex justify-between">
                      <dt class="text-muted-foreground">Contract Period</dt>
                      <dd class="font-semibold">
                        {Calendar.strftime(@contract.start_date, "%b %d")} - {Calendar.strftime(
                          @contract.end_date,
                          "%b %d, %Y"
                        )}
                      </dd>
                    </div>
                  </dl>
                </.card_content>
              </.card>

              <.card class="mt-4">
                <.card_header>
                  <.card_title>Dispute Process</.card_title>
                </.card_header>
                <.card_content>
                  <ol class="space-y-4 list-decimal list-inside text-sm text-muted-foreground">
                    <li>Our team will review your case within 24 hours</li>
                    <li>Both parties will be contacted for additional information</li>
                    <li>Resolution typically occurs within 5 business days</li>
                    <li>Funds remain in escrow until the dispute is resolved</li>
                  </ol>
                </.card_content>
              </.card>
            </div>
          </div>
        </.drawer_content>
      </.drawer>
    </div>
    """
  end
end
