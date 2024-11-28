defmodule AlgoraWeb.Contract.ViewLive do
  use AlgoraWeb, :live_view

  alias Algora.{Contracts, Chat, Reviews, Repo, Money}

  def render(assigns) do
    ~H"""
    <div class="flex">
      <!-- Main Content - Make this scrollable -->
      <.scroll_area class="flex-1 h-[calc(100vh-64px)]">
        <div class="max-w-4xl mx-auto p-4">
          <!-- Header -->
          <div class="flex justify-between items-center">
            <div class="flex items-center gap-4">
              <div class="flex -space-x-2">
                <.avatar class="h-12 w-12 ring-2 ring-background">
                  <.avatar_image src={@contract.client.avatar_url} />
                  <.avatar_fallback>
                    <%= String.slice(@contract.client.name, 0, 2) %>
                  </.avatar_fallback>
                </.avatar>
                <.avatar class="h-12 w-12 ring-2 ring-background">
                  <.avatar_image src={@contract.provider.avatar_url} />
                  <.avatar_fallback>
                    <%= String.slice(@contract.provider.name, 0, 2) %>
                  </.avatar_fallback>
                </.avatar>
              </div>
              <div>
                <h1 class="text-2xl font-semibold">
                  Contract with <%= @contract.provider.name %>
                </h1>
                <p class="text-sm text-muted-foreground">
                  Started <%= Calendar.strftime(@contract.start_date, "%B %d, %Y") %>
                </p>
              </div>
            </div>
            <div>
              <.badge variant="primary">Active</.badge>
            </div>
          </div>
          <!-- Stats Grid -->
          <div class="grid grid-cols-4 gap-4 mt-8">
            <.card>
              <.card_content class="pt-6">
                <div class="text-sm text-muted-foreground mb-2">Hourly Rate</div>
                <div class="text-2xl font-semibold font-display">
                  <%= Money.format!(@contract.hourly_rate, "USD") %>/hr
                </div>
              </.card_content>
            </.card>

            <.card>
              <.card_content class="pt-6">
                <div class="text-sm text-muted-foreground mb-2">Hours per Week</div>
                <div class="text-2xl font-semibold font-display">
                  <%= @contract.hours_per_week %>h
                </div>
              </.card_content>
            </.card>
            <.card>
              <.card_content class="pt-6">
                <div class="text-sm text-muted-foreground mb-2">In Escrow</div>
                <div class="text-2xl font-semibold font-display">
                  <%= Money.format!(@escrow_amount, "USD") %>
                </div>
              </.card_content>
            </.card>
            <.card>
              <.card_content class="pt-6">
                <div class="text-sm text-muted-foreground mb-2">Total Paid</div>
                <div class="text-2xl font-semibold font-display">
                  <%= Money.format!(@contract.total_paid, "USD") %>
                </div>
              </.card_content>
            </.card>
          </div>
          <!-- Tabs -->
          <.tabs :let={builder} id="contract-tabs" default="payments" class="mt-8">
            <.tabs_list class="w-full flex space-x-1 rounded-lg bg-muted p-1">
              <.tabs_trigger builder={builder} value="payments" class="flex-1">
                <.icon name="tabler-credit-card" class="w-4 h-4 mr-2" /> Payments
              </.tabs_trigger>
              <.tabs_trigger builder={builder} value="details" class="flex-1">
                <.icon name="tabler-file-text" class="w-4 h-4 mr-2" /> Contract Details
              </.tabs_trigger>
              <.tabs_trigger builder={builder} value="activity" class="flex-1">
                <.icon name="tabler-history" class="w-4 h-4 mr-2" /> Activity
              </.tabs_trigger>
            </.tabs_list>

            <.tabs_content value="payments">
              <.card>
                <.card_header>
                  <.card_title>Payment Timeline</.card_title>
                  <.card_description>
                    Track upcoming payments and view past transactions
                  </.card_description>
                </.card_header>
                <.card_content>
                  <div class="space-y-8">
                    <%= for contract <- get_contract_chain(@contract) do %>
                      <%= case get_payment_status(contract) do %>
                        <% {:pending_release, timesheet} -> %>
                          <div class="-mx-4 flex items-center justify-between bg-muted/30 p-4 rounded-lg">
                            <div class="flex items-center gap-4">
                              <div class="h-9 w-9 rounded-full bg-primary/20 flex items-center justify-center">
                                <.icon name="tabler-clock" class="w-5 h-5 text-primary" />
                              </div>
                              <div>
                                <div class="font-medium">
                                  Ready to release payment for <%= timesheet.hours_worked %> hours
                                </div>
                                <div class="text-sm text-muted-foreground">
                                  <%= Calendar.strftime(timesheet.start_date, "%B %d") %> - <%= Calendar.strftime(
                                    timesheet.end_date,
                                    "%B %d, %Y"
                                  ) %>
                                </div>
                              </div>
                            </div>
                            <div class="flex items-center gap-2">
                              <div class="text-right mr-4">
                                <div class="font-medium font-display">
                                  <%= Money.format!(calculate_amount(contract, timesheet), "USD") %>
                                </div>
                                <div class="text-sm text-muted-foreground">
                                  Ready to Release
                                </div>
                              </div>

                              <div class="flex items-center gap-2">
                                <.button phx-click={
                                  JS.push("show_release_renew_modal",
                                    value: %{contract_id: contract.id}
                                  )
                                }>
                                  Release & Renew
                                </.button>

                                <.dropdown_menu>
                                  <.dropdown_menu_trigger>
                                    <.button variant="ghost" size="icon">
                                      <.icon name="tabler-dots-vertical" class="w-4 h-4" />
                                    </.button>
                                  </.dropdown_menu_trigger>
                                  <.dropdown_menu_content>
                                    <.dropdown_menu_item phx-click={
                                      JS.push("show_release_modal",
                                        value: %{contract_id: contract.id}
                                      )
                                    }>
                                      <.icon name="tabler-arrow-right" class="w-4 h-4 mr-2" />
                                      Release without renew
                                    </.dropdown_menu_item>
                                    <.dropdown_menu_separator />
                                    <.dropdown_menu_item
                                      phx-click={
                                        JS.push("show_dispute_modal",
                                          value: %{contract_id: contract.id}
                                        )
                                      }
                                      class="text-destructive"
                                    >
                                      <.icon name="tabler-alert-triangle" class="w-4 h-4 mr-2" />
                                      Dispute
                                    </.dropdown_menu_item>
                                  </.dropdown_menu_content>
                                </.dropdown_menu>
                              </div>
                            </div>
                          </div>
                        <% {:processing, timesheet} -> %>
                          <div class="flex items-center justify-between">
                            <div class="flex items-center gap-4">
                              <div class="h-9 w-9 rounded-full bg-warning/20 flex items-center justify-center">
                                <.icon
                                  name="tabler-loader-2"
                                  class="w-5 h-5 text-warning animate-spin"
                                />
                              </div>
                              <div>
                                <div class="font-medium">
                                  Processing payment for <%= timesheet.hours_worked %> hours
                                </div>
                                <div class="text-sm text-muted-foreground">
                                  <%= Calendar.strftime(timesheet.start_date, "%B %d") %> - <%= Calendar.strftime(
                                    timesheet.end_date,
                                    "%B %d, %Y"
                                  ) %>
                                </div>
                              </div>
                            </div>
                            <div class="text-right">
                              <div class="font-medium font-display">
                                <%= Money.format!(calculate_amount(contract, timesheet), "USD") %>
                              </div>
                              <div class="text-sm text-muted-foreground">Processing</div>
                            </div>
                          </div>
                        <% {:completed, timesheet, transaction} -> %>
                          <div class="flex items-center justify-between">
                            <div class="flex items-center gap-4">
                              <div class="h-9 w-9 rounded-full bg-success/20 flex items-center justify-center">
                                <.icon name="tabler-check" class="w-5 h-5 text-success" />
                              </div>
                              <div>
                                <div class="font-medium">
                                  Payment for <%= timesheet.hours_worked %> hours
                                </div>
                                <div class="text-sm text-muted-foreground">
                                  <%= Calendar.strftime(timesheet.start_date, "%B %d") %> - <%= Calendar.strftime(
                                    timesheet.end_date,
                                    "%B %d, %Y"
                                  ) %>
                                </div>
                              </div>
                            </div>
                            <div class="text-right">
                              <div class="font-medium font-display">
                                <%= Money.format!(transaction.amount, "USD") %>
                              </div>
                              <div class="text-sm text-muted-foreground">Paid</div>
                            </div>
                          </div>
                      <% end %>
                    <% end %>
                  </div>
                </.card_content>
              </.card>
            </.tabs_content>

            <.tabs_content value="details">
              <div class="grid grid-cols-2 gap-2">
                <.card>
                  <.card_header>
                    <.card_title>Company</.card_title>
                  </.card_header>
                  <.card_content>
                    <div class="flex items-center gap-4">
                      <.avatar class="h-16 w-16">
                        <.avatar_image src={@contract.client.avatar_url} />
                      </.avatar>
                      <div>
                        <div class="font-medium text-lg"><%= @contract.client.name %></div>
                        <div class="text-sm text-muted-foreground">
                          @<%= @contract.client.handle %>
                        </div>
                      </div>
                    </div>
                  </.card_content>
                </.card>

                <.card>
                  <.card_header>
                    <.card_title>Developer</.card_title>
                  </.card_header>
                  <.card_content>
                    <div class="space-y-4">
                      <div class="flex items-center gap-4">
                        <.avatar class="h-16 w-16">
                          <.avatar_image src={@contract.provider.avatar_url} />
                        </.avatar>
                        <div>
                          <div class="font-medium text-lg"><%= @contract.provider.name %></div>
                          <div class="text-sm text-muted-foreground">
                            @<%= @contract.provider.handle %>
                          </div>
                        </div>
                      </div>

                      <div class="pt-4 space-y-2">
                        <div class="flex items-center gap-2 text-sm text-muted-foreground">
                          <.icon name="tabler-map-pin" class="w-4 h-4" />
                          <%= @contract.provider.location %>
                        </div>
                        <%= if @contract.provider.timezone do %>
                          <div class="flex items-center gap-2 text-sm text-muted-foreground">
                            <.icon name="tabler-clock" class="w-4 h-4" />
                            <%= Algora.Time.friendly_timezone(@contract.provider.timezone) %>
                          </div>
                        <% end %>
                      </div>

                      <div class="flex flex-wrap gap-2 pt-2">
                        <%= for skill <- @contract.provider.tech_stack do %>
                          <span class="rounded-lg px-2 py-0.5 text-xs ring-1 ring-border bg-secondary">
                            <%= skill %>
                          </span>
                        <% end %>
                      </div>
                    </div>
                  </.card_content>
                </.card>
              </div>
            </.tabs_content>

            <.tabs_content value="activity">
              <.card>
                <.card_header>
                  <.card_title>Contract Activity</.card_title>
                </.card_header>
                <.card_content>
                  <div class="space-y-4">
                    <div class="flex items-center gap-4">
                      <div class="h-9 w-9 rounded-full bg-muted flex items-center justify-center">
                        <.icon name="tabler-file-check" class="w-5 h-5" />
                      </div>
                      <div>
                        <div class="font-medium">Contract signed by both parties</div>
                        <div class="text-sm text-muted-foreground">
                          <%= Calendar.strftime(@contract.start_date, "%B %d, %Y") %>
                        </div>
                      </div>
                    </div>
                  </div>
                </.card_content>
              </.card>
            </.tabs_content>
          </.tabs>
        </div>
      </.scroll_area>
      <!-- Chat Sidebar - Fixed position -->
      <div class="h-[calc(100vh-64px)] w-[400px] border-l border-border flex flex-col flex-none">
        <div class="flex justify-between items-center border-b border-border p-4 flex-none bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div class="flex items-center gap-3">
            <div class="relative">
              <.avatar>
                <.avatar_image src={@contract.provider.avatar_url} alt="Developer avatar" />
                <.avatar_fallback>
                  <%= String.slice(@contract.provider.name, 0, 2) %>
                </.avatar_fallback>
              </.avatar>
              <div class="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-success border-2 border-background">
              </div>
            </div>
            <div>
              <h2 class="text-lg font-semibold"><%= @contract.provider.name %></h2>
              <p class="text-xs text-muted-foreground">Active now</p>
            </div>
          </div>
        </div>

        <.scroll_area
          class="flex-1 p-4 flex flex-col-reverse h-full gap-6"
          id="messages-container"
          phx-hook="ScrollToBottom"
        >
          <div class="space-y-6">
            <%= for {date, messages} <- Enum.group_by(@messages, & &1.date) do %>
              <div class="flex items-center justify-center">
                <div class="text-xs text-muted-foreground bg-background px-2 py-1 rounded-full">
                  <%= date %>
                </div>
              </div>

              <%= for message <- messages do %>
                <div class="flex gap-3 group">
                  <.avatar class="h-8 w-8">
                    <.avatar_image src={message.avatar_url} />
                    <.avatar_fallback>
                      <%= String.slice(message.sender.name, 0, 2) %>
                    </.avatar_fallback>
                  </.avatar>
                  <div class="relative max-w-[80%] rounded-2xl p-3 bg-muted rounded-tl-none">
                    <%= message.content %>
                    <div class="text-[10px] mt-1 text-muted-foreground">
                      <%= message.sent_at %>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </.scroll_area>

        <div class="mt-auto border-t border-border p-4 flex-none bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <form phx-submit="send_message" class="flex gap-2 items-center">
            <.button type="button" variant="ghost" size="icon">
              <.icon name="tabler-plus" class="w-4 h-4" />
            </.button>
            <div class="flex-1 relative">
              <.input
                type="text"
                name="message"
                value=""
                placeholder="Type a message..."
                class="flex-1 pr-24"
              />
              <div class="absolute right-2 top-1/2 -translate-y-1/2 flex gap-1">
                <.button type="button" variant="ghost" size="icon-sm">
                  <.icon name="tabler-mood-smile" class="w-4 h-4" />
                </.button>
                <.button type="button" variant="ghost" size="icon-sm">
                  <.icon name="tabler-paperclip" class="w-4 h-4" />
                </.button>
              </div>
            </div>
            <.button type="submit" size="icon">
              <.icon name="tabler-send" class="w-4 h-4" />
            </.button>
          </form>
        </div>
      </div>
    </div>
    <.drawer show={@show_release_renew_modal} on_cancel="close_drawer">
      <.drawer_header>
        Release Payment & Renew Contract
      </.drawer_header>
      <.drawer_content class="mt-4">
        <div class="grid grid-cols-2 gap-8">
          <div class="space-y-8">
            <.form_item>
              <.form_label class="text-lg font-semibold mb-6">
                How was your experience working with <%= @contract.provider.name %>?
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
                      Payout amount (<%= @contract.hours_per_week %> hours x <%= Money.format!(
                        @contract.hourly_rate,
                        "USD"
                      ) %>/hr)
                    </dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.format!(@escrow_amount, "USD") %>
                    </dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">
                      Escrow balance
                    </dt>
                    <dd class="font-semibold font-display tabular-nums">
                      -<%= Money.format!(@escrow_amount, "USD") %>
                    </dd>
                  </div>
                  <div class="flex justify-between opacity-0">
                    <dt class="text-muted-foreground">
                      Algora fees (<%= @fee_data.fee_percentage %>%)
                    </dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.format!(
                        Decimal.mult(
                          @escrow_amount,
                          Decimal.div(Decimal.new(@fee_data.fee_percentage), Decimal.new(100))
                        ),
                        "USD"
                      ) %>
                    </dd>
                  </div>
                  <div class="h-px bg-border" />
                  <div class="flex justify-between">
                    <dt class="font-medium">Total Due</dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.format!(0, "USD") %>
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
                      <span><%= tier.fee %>%</span>
                    <% end %>
                  </div>

                  <div class="relative">
                    <!-- Progress bar -->
                    <div class="h-2 bg-muted/50 rounded-full">
                      <div
                        class="h-full bg-primary rounded-full transition-all duration-500"
                        style={"width: #{@fee_data.progress}%"}
                      />
                    </div>
                    <!-- Threshold circles -->
                    <div class="absolute top-1/2 -translate-y-1/2 w-full flex justify-between pointer-events-none">
                      <%= for tier <- @fee_data.fee_tiers do %>
                        <div class={[
                          "h-4 w-4 rounded-full border-2 border-background",
                          if Decimal.compare(@fee_data.total_paid, Decimal.new(tier.threshold)) !=
                               :lt do
                            "bg-success"
                          else
                            "bg-muted"
                          end
                        ]}>
                        </div>
                      <% end %>
                    </div>
                  </div>
                  <!-- Updated threshold numbers alignment -->
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
                            do: "left: #{index * 100 / (length(@fee_data.fee_tiers) - 1)}%"
                        }
                      >
                        <%= Money.format!(Decimal.new(tier.threshold), "USD") %>
                      </div>
                    <% end %>
                  </div>
                </div>

                <div class="text-base text-muted-foreground">
                  Current fee:
                  <span class="font-semibold font-display"><%= @fee_data.fee_percentage %>%</span>
                </div>
                <div class="text-base text-muted-foreground">
                  Total paid to date:
                  <span class="font-semibold font-display">
                    <%= Money.format!(@fee_data.total_paid, "USD") %>
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
                      Renewal amount (<%= @contract.hours_per_week %> hours x <%= Money.format!(
                        @contract.hourly_rate,
                        "USD"
                      ) %>/hr)
                    </dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.format!(@escrow_amount, "USD") %>
                    </dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">
                      Algora fees (<%= @fee_data.fee_percentage %>%)
                    </dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.format!(
                        Decimal.mult(
                          @escrow_amount,
                          Decimal.div(Decimal.new(@fee_data.fee_percentage), Decimal.new(100))
                        ),
                        "USD"
                      ) %>
                    </dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">Transaction fees (4%)</dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.format!(
                        Decimal.mult(@escrow_amount, Decimal.new("0.04")),
                        "USD"
                      ) %>
                    </dd>
                  </div>
                  <div class="h-px bg-border" />
                  <div class="flex justify-between">
                    <dt class="font-medium">Total Due</dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.format!(
                        Decimal.mult(@escrow_amount, Decimal.new("1.23")),
                        "USD"
                      ) %>
                    </dd>
                  </div>
                </dl>
              </.card_content>
            </.card>
            <div class="ml-auto flex gap-4">
              <.button variant="outline" type="button" on_cancel="close_drawer">
                Cancel
              </.button>
              <.button type="submit">
                <.icon name="tabler-check" class="w-4 h-4 mr-2" /> Confirm Release & Renew
              </.button>
            </div>
          </div>
        </div>
      </.drawer_content>
    </.drawer>

    <.drawer show={@show_release_modal} on_cancel="close_drawer">
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

            <div class="flex gap-4">
              <.button variant="outline" type="button" on_cancel="close_drawer">
                Cancel
              </.button>
              <.button type="submit">
                <.icon name="tabler-check" class="w-4 h-4 mr-2" /> Confirm Release
              </.button>
            </div>
          </form>

          <div>
            <.card>
              <.card_header>
                <.card_title>Payment Details</.card_title>
              </.card_header>
              <.card_content>
                <dl class="space-y-4">
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">Amount</dt>
                    <dd class="font-semibold">
                      <%= Money.format!(@escrow_amount, "USD") %>
                    </dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">Hours</dt>
                    <dd class="font-semibold">20 hours</dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">Rate</dt>
                    <dd class="font-semibold">
                      <%= Money.format!(@contract.hourly_rate, "USD") %>/hr
                    </dd>
                  </div>
                </dl>
              </.card_content>
            </.card>
          </div>
        </div>
      </.drawer_content>
    </.drawer>

    <.drawer show={@show_dispute_modal} on_cancel="close_drawer">
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
                      <%= Money.format!(@escrow_amount, "USD") %>
                    </dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">Contract Period</dt>
                    <dd class="font-semibold">
                      <%= Calendar.strftime(@contract.start_date, "%B %d") %> - <%= Calendar.strftime(
                        @contract.end_date,
                        "%B %d, %Y"
                      ) %>
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
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    contract =
      Contracts.get_contract!(id)
      |> Repo.preload([
        :client,
        :provider,
        :timesheets,
        :transactions,
        :reviews,
        original_contract: [
          :timesheets,
          :transactions,
          renewals: [
            :timesheets,
            :transactions
          ]
        ],
        renewals: [
          :timesheets,
          :transactions
        ]
      ])

    transactions = Contracts.get_all_transactions_for_contract(contract.id)

    {:ok, thread} = get_or_create_thread(contract)

    messages =
      Chat.list_messages(thread.id)
      |> Repo.preload(:sender)
      |> Enum.map(&format_message(&1, socket.assigns.current_user))

    fee_data = calculate_fee_data(contract)

    escrow_amount = Decimal.mult(contract.hourly_rate, Decimal.new(contract.hours_per_week))

    {:ok,
     socket
     |> assign(:contract, contract)
     |> assign(:transactions, transactions)
     |> assign(:escrow_amount, escrow_amount)
     |> assign(:page_title, "Contract with #{contract.provider.name}")
     |> assign(:messages, messages)
     |> assign(:thread, thread)
     |> assign(:show_release_renew_modal, false)
     |> assign(:show_release_modal, false)
     |> assign(:show_dispute_modal, false)
     |> assign(:fee_data, fee_data)}
  end

  def handle_event("release_and_renew", %{"feedback" => feedback}, socket) do
    contract = socket.assigns.contract

    {:ok, {_updated_contract, _charge, _transfer}} =
      Contracts.process_payment(contract, %{
        stripe_charge_id: "ch_xxx",
        stripe_transfer_id: "tr_xxx",
        stripe_metadata: %{},
        fee_percentage: socket.assigns.fee_data.fee_percentage
      })

    {:ok, _review} =
      Reviews.create_review(%{
        contract_id: contract.id,
        reviewer_id: socket.assigns.current_user.id,
        reviewee_id: contract.provider_id,
        rating: 5,
        content: feedback,
        visibility: :public
      })

    {:ok, new_contract} = Contracts.renew_contract(contract)

    {:noreply,
     socket
     |> assign(:contract, new_contract)
     |> assign(:show_release_renew_modal, false)
     |> put_flash(:info, "Payment released and contract renewed successfully")}
  end

  def handle_event("send_message", %{"message" => content}, socket) do
    {:ok, message} =
      Chat.send_message(
        socket.assigns.thread.id,
        socket.assigns.current_user.id,
        content
      )

    message = Repo.preload(message, :sender)
    new_message = format_message(message, socket.assigns.current_user)

    {:noreply, update(socket, :messages, &(&1 ++ [new_message]))}
  end

  defp get_or_create_thread(contract) do
    case Chat.get_thread_for_users(contract.client_id, contract.provider_id) do
      nil -> Chat.create_direct_thread(contract.client, contract.provider)
      thread -> {:ok, thread}
    end
  end

  defp format_message(message, current_user) do
    %{
      id: message.id,
      sender: message.sender,
      content: message.content,
      sent_at: format_time(message.inserted_at),
      date: format_date(message.inserted_at),
      is_self: message.sender_id == current_user.id,
      avatar_url: message.sender.avatar_url
    }
  end

  defp calculate_fee_data(contract) do
    fee_tiers = [
      %{threshold: 0, fee: 19},
      %{threshold: 3000, fee: 15},
      %{threshold: 5000, fee: 10},
      %{threshold: 15000, fee: 5}
    ]

    %{
      total_paid: contract.total_paid,
      fee_tiers: fee_tiers,
      fee_percentage: calculate_fee_percentage(contract.total_paid),
      progress: calculate_progress(contract.total_paid)
    }
  end

  defp calculate_fee_percentage(total_paid) do
    cond do
      Decimal.compare(total_paid, Decimal.new("15000")) != :lt -> 5
      Decimal.compare(total_paid, Decimal.new("5000")) != :lt -> 10
      Decimal.compare(total_paid, Decimal.new("3000")) != :lt -> 15
      true -> 19
    end
  end

  defp calculate_progress(total_paid) do
    case {
      Decimal.compare(total_paid, Decimal.new("5000")),
      Decimal.compare(total_paid, Decimal.new("3000"))
    } do
      {:lt, :gt} ->
        start_percent = 40.0
        end_percent = 60.0
        progress_in_range = (Decimal.to_float(total_paid) - 3000) / (5000 - 3000)
        start_percent + (end_percent - start_percent) * progress_in_range

      _ ->
        30.0
    end
  end

  defp format_time(datetime) do
    datetime
    |> DateTime.to_time()
    |> Time.to_string()
    |> String.slice(0..4)
  end

  defp format_date(datetime) do
    case Date.diff(Date.utc_today(), DateTime.to_date(datetime)) do
      0 -> "Today"
      1 -> "Yesterday"
      n when n <= 7 -> Calendar.strftime(datetime, "%A")
      _ -> Calendar.strftime(datetime, "%B %d")
    end
  end

  defp get_contract_chain(contract) do
    case contract.original_contract_id do
      nil -> [contract | contract.renewals]
      _ -> [contract.original_contract | contract.original_contract.renewals]
    end
    |> Enum.sort_by(& &1.start_date, {:desc, DateTime})
  end

  defp get_payment_status(contract) do
    case {get_latest_timesheet(contract), get_latest_transaction(contract)} do
      {nil, _} ->
        nil

      {timesheet, nil} ->
        {:pending_release, timesheet}

      {timesheet, %{stripe_transfer_id: nil, status: :processing}} ->
        {:processing, timesheet}

      {timesheet, transaction = %{stripe_transfer_id: transfer_id}}
      when not is_nil(transfer_id) ->
        {:completed, timesheet, transaction}

      {timesheet, _} ->
        {:pending_release, timesheet}
    end
  end

  defp get_latest_timesheet(contract) do
    contract.timesheets
    |> Enum.sort_by(& &1.end_date, {:desc, DateTime})
    |> List.first()
  end

  defp get_latest_transaction(contract) do
    contract.transactions
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
    |> List.first()
  end

  defp calculate_amount(contract, timesheet) do
    Decimal.mult(contract.hourly_rate, Decimal.new(timesheet.hours_worked))
  end
end
