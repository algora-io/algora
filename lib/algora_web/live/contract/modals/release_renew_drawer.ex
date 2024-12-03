defmodule AlgoraWeb.Contract.Modals.ReleaseRenewDrawer do
  use AlgoraWeb.LiveComponent

  alias Algora.Contracts
  alias Algora.FeeTier
  alias Algora.MoneyUtils
  alias Algora.Util

  attr :show, :boolean, required: true
  attr :on_cancel, :string, required: true
  attr :contract, :map, required: true
  attr :timesheet, :map, required: true
  attr :prepaid_amount, :map, required: true
  attr :fee_data, :map, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.drawer show={@show} on_cancel={@on_cancel}>
        <.drawer_header>
          Release Payment & Renew Contract
        </.drawer_header>
        <.drawer_content class="mt-4">
          <div class="grid grid-cols-2 gap-8">
            <div class="space-y-8">
              <.form_item>
                <.form_label class="text-lg font-semibold mb-6">
                  How was your experience working with <%= @contract.contractor.name %>?
                </.form_label>
                <.form_control>
                  <.input
                    type="textarea"
                    rows={6}
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
              <.card>
                <.card_header>
                  <.card_title>Past Escrow Release</.card_title>
                </.card_header>
                <.card_content>
                  <dl class="space-y-4">
                    <div class="flex justify-between">
                      <dt class="text-muted-foreground">
                        Payout amount (<%= @timesheet.hours_worked %> hours x <%= MoneyUtils.fmt_precise!(
                          @contract.hourly_rate
                        ) %>/hr)
                      </dt>
                      <dd class="font-semibold font-display tabular-nums">
                        <%= MoneyUtils.fmt_precise!(Contracts.calculate_transfer_amount(@contract, @timesheet)) %>
                      </dd>
                    </div>
                    <div class="flex justify-between">
                      <dt class="text-muted-foreground">
                        Escrow balance
                      </dt>
                      <dd class="font-semibold font-display tabular-nums">
                        -<%= MoneyUtils.fmt_precise!(@prepaid_amount) %>
                      </dd>
                    </div>
                    <div class="h-5"></div>
                    <div class="h-px bg-border" />
                    <div class="flex justify-between">
                      <dt class="font-medium">Total Due</dt>
                      <dd class="font-semibold font-display tabular-nums">
                        <%= MoneyUtils.fmt_precise!(
                          Money.sub!(
                            Contracts.calculate_transfer_amount(@contract, @timesheet),
                            @prepaid_amount
                          )
                        ) %>
                      </dd>
                    </div>
                  </dl>
                </.card_content>
              </.card>
            </div>
            <div class="flex flex-col gap-8">
              <div>
                <h3 class="text-lg font-semibold mb-6">Algora Fee Tier</h3>
                <div class="space-y-2">
                  <div class="space-y-4">
                    <div class="flex justify-between text-lg font-medium font-display">
                      <%= for tier <- @fee_data.fee_tiers do %>
                        <span><%= Util.format_pct(tier.fee) %></span>
                      <% end %>
                    </div>

                    <div class="relative">
                      <!-- Progress bar -->
                      <div class="h-2 bg-muted/50 rounded-full">
                        <div
                          class="h-full bg-primary rounded-full transition-all duration-500"
                          style={"width: #{Util.format_pct(@fee_data.progress)}"}
                        />
                      </div>
                      <!-- Threshold circles -->
                      <div class="absolute top-1/2 -translate-y-1/2 w-full flex justify-between pointer-events-none">
                        <%= for tier <- @fee_data.fee_tiers do %>
                          <div class={
                            classes([
                              "h-4 w-4 rounded-full border-2 border-background",
                              if(FeeTier.threshold_met?(@fee_data.total_paid, tier),
                                do: "bg-success",
                                else: "bg-muted"
                              )
                            ])
                          }>
                          </div>
                        <% end %>
                      </div>
                    </div>
                    <div class="flex justify-between text-lg font-display font-medium relative">
                      <%= for {tier, index} <- Enum.with_index(@fee_data.fee_tiers) do %>
                        <div
                          class={
                            classes([
                              "transform translate-x-1/3",
                              index == 0 && "translate-x-0",
                              index == length(@fee_data.fee_tiers) - 1 && "translate-x-0"
                            ])
                          }
                          style={
                            if !Enum.member?([0, length(@fee_data.fee_tiers) - 1], index),
                              do: "left: #{Util.format_pct(tier.progress)}"
                          }
                        >
                          <%= Money.to_string!(tier.threshold) %>
                        </div>
                      <% end %>
                    </div>
                  </div>

                  <div class="text-base text-muted-foreground">
                    Current fee:
                    <span class="font-semibold font-display">
                      <%= Util.format_pct(@fee_data.current_fee) %>
                    </span>
                  </div>
                  <div class="text-base text-muted-foreground">
                    Total paid to date:
                    <span class="font-semibold font-display">
                      <%= MoneyUtils.fmt_precise!(@fee_data.total_paid) %>
                    </span>
                  </div>
                </div>
              </div>
              <.card class="mt-1">
                <.card_header>
                  <.card_title>New Escrow Payment Summary</.card_title>
                </.card_header>
                <.card_content>
                  <dl class="space-y-4">
                    <div class="flex justify-between">
                      <dt class="text-muted-foreground">
                        Renewal amount (<%= @contract.hours_per_week %> hours x <%= MoneyUtils.fmt_precise!(
                          @contract.hourly_rate
                        ) %>/hr)
                      </dt>
                      <dd class="font-semibold font-display tabular-nums">
                        <%= MoneyUtils.fmt_precise!(@prepaid_amount) %>
                      </dd>
                    </div>
                    <div class="flex justify-between">
                      <dt class="text-muted-foreground">
                        Algora fees (<%= Util.format_pct(@fee_data.current_fee) %>)
                      </dt>
                      <dd class="font-semibold font-display tabular-nums">
                        <%= MoneyUtils.fmt_precise!(Money.mult!(@prepaid_amount, @fee_data.current_fee)) %>
                      </dd>
                    </div>
                    <div class="flex justify-between">
                      <dt class="text-muted-foreground">
                        Transaction fees (<%= Util.format_pct(@fee_data.transaction_fee) %>)
                      </dt>
                      <dd class="font-semibold font-display tabular-nums">
                        <%= MoneyUtils.fmt_precise!(Money.mult!(@prepaid_amount, @fee_data.transaction_fee)) %>
                      </dd>
                    </div>
                    <div class="h-px bg-border" />
                    <div class="flex justify-between">
                      <dt class="font-medium">Total Due</dt>
                      <dd class="font-semibold font-display tabular-nums">
                        <%= MoneyUtils.fmt_precise!(
                          Money.mult!(@prepaid_amount, Decimal.add(1, @fee_data.total_fee))
                        ) %>
                      </dd>
                    </div>
                  </dl>
                </.card_content>
              </.card>
              <div class="ml-auto flex gap-4">
                <.button variant="outline" type="button" phx-click={@on_cancel}>
                  Cancel
                </.button>
                <.button phx-click="release_and_renew" phx-target={@myself} type="button">
                  <.icon name="tabler-check" class="w-4 h-4 mr-2" /> Confirm Release & Renew
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
  def handle_event("release_and_renew", _params, socket) do
    %{timesheet: timesheet} = socket.assigns

    case Contracts.release_and_renew(timesheet) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:success, "Payment released and contract renewed")}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error releasing payment: #{inspect(error)}")}
    end
  end
end
