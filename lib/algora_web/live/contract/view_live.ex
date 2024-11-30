defmodule AlgoraWeb.Contract.ViewLive do
  use AlgoraWeb, :live_view

  alias Algora.{Contracts, Chat, Reviews, Repo, Organizations}

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
                  Started <%= Calendar.strftime(@contract.start_date, "%b %d, %Y") %>
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
                <div class="text-sm text-muted-foreground mb-2">Hourly rate</div>
                <div class="text-2xl font-semibold font-display">
                  <%= Money.to_string!(@contract.hourly_rate) %>/hr
                </div>
              </.card_content>
            </.card>

            <.card>
              <.card_content class="pt-6">
                <div class="text-sm text-muted-foreground mb-2">Hours per week</div>
                <div class="text-2xl font-semibold font-display">
                  <%= @contract.hours_per_week %>
                </div>
              </.card_content>
            </.card>
            <.card>
              <.card_content class="pt-6">
                <div class="text-sm text-muted-foreground mb-2">In escrow</div>
                <div class="text-2xl font-semibold font-display">
                  <%= Money.to_string!(@escrow_amount) %>
                </div>
              </.card_content>
            </.card>
            <.card>
              <.card_content class="pt-6">
                <div class="text-sm text-muted-foreground mb-2">Total paid</div>
                <div class="text-2xl font-semibold font-display">
                  <%= Money.to_string!(@contract.total_paid) %>
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
                                  <%= Calendar.strftime(@contract.start_date, "%b %d") %> - <%= Calendar.strftime(
                                    @contract.end_date,
                                    "%b %d, %Y"
                                  ) %>
                                </div>
                              </div>
                            </div>
                            <div class="flex items-center gap-2">
                              <div class="text-right mr-4">
                                <div class="font-medium font-display">
                                  <%= Money.to_string!(calculate_amount(contract, timesheet)) %>
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
                                  <%= Calendar.strftime(timesheet.start_date, "%b %d") %> - <%= Calendar.strftime(
                                    timesheet.end_date,
                                    "%b %d, %Y"
                                  ) %>
                                </div>
                              </div>
                            </div>
                            <div class="text-right">
                              <div class="font-medium font-display">
                                <%= Money.to_string!(calculate_amount(contract, timesheet)) %>
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
                                  <%= Calendar.strftime(timesheet.start_date, "%b %d") %> - <%= Calendar.strftime(
                                    timesheet.end_date,
                                    "%b %d, %Y"
                                  ) %>
                                </div>
                              </div>
                            </div>
                            <div class="text-right">
                              <div class="font-medium font-display">
                                <%= Money.to_string!(transaction.amount) %>
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
                    <.card_title>Client</.card_title>
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
                    <div class="pt-6 flex flex-wrap gap-2">
                      <%= for tech <- @contract.client.tech_stack do %>
                        <span class="rounded-lg px-2 py-0.5 text-xs ring-1 ring-border bg-secondary">
                          <%= tech %>
                        </span>
                      <% end %>
                    </div>
                    <div class="pt-6 flex -space-x-1">
                      <%= for member <- @org_members do %>
                        <.avatar class="h-9 w-9 ring-2 ring-background">
                          <.avatar_image src={member.avatar_url} />
                          <.avatar_fallback>
                            <%= String.slice(member.name, 0, 2) %>
                          </.avatar_fallback>
                        </.avatar>
                      <% end %>
                    </div>
                  </.card_content>
                </.card>

                <.card>
                  <.card_header>
                    <.card_title>Provider</.card_title>
                  </.card_header>
                  <.card_content>
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
                    <div class="pt-6 flex flex-wrap gap-2">
                      <%= for tech <- @contract.provider.tech_stack do %>
                        <span class="rounded-lg px-2 py-0.5 text-xs ring-1 ring-border bg-secondary">
                          <%= tech %>
                        </span>
                      <% end %>
                    </div>
                    <div class="pt-6 space-y-2">
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
                    <%= for activity <- get_contract_activity(@contract) do %>
                      <.timeline_activity activity={activity} />
                    <% end %>
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
            <%= for {date, messages} <- @messages
                |> Enum.group_by(fn msg ->
                  case Date.diff(Date.utc_today(), DateTime.to_date(msg.inserted_at)) do
                    0 -> "Today"
                    1 -> "Yesterday"
                    n when n <= 7 -> Calendar.strftime(msg.inserted_at, "%A")
                    _ -> Calendar.strftime(msg.inserted_at, "%b %d")
                  end
                end)
                |> Enum.sort_by(fn {_, msgs} -> hd(msgs).inserted_at end, :asc) do %>
              <div class="flex items-center justify-center">
                <div class="text-xs text-muted-foreground bg-background px-2 py-1 rounded-full">
                  <%= date %>
                </div>
              </div>

              <%= for message <- Enum.sort_by(messages, & &1.inserted_at, :asc) do %>
                <div class="flex gap-3 group">
                  <.avatar class="h-8 w-8">
                    <.avatar_image src={message.sender.avatar_url} />
                    <.avatar_fallback>
                      <%= String.slice(message.sender.name, 0, 2) %>
                    </.avatar_fallback>
                  </.avatar>
                  <div class="relative max-w-[80%] rounded-2xl p-3 bg-muted rounded-tl-none">
                    <%= message.content %>
                    <div class="text-[10px] mt-1 text-muted-foreground">
                      <%= message.inserted_at
                      |> DateTime.to_time()
                      |> Time.to_string()
                      |> String.slice(0..4) %>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </.scroll_area>

        <div class="mt-auto border-t border-border p-4 flex-none bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <form phx-submit="send_message" class="flex gap-2 items-center">
            <div class="flex-1 relative">
              <.input
                id="message-input"
                type="text"
                name="message"
                value=""
                placeholder="Type a message..."
                autocomplete="off"
                class="flex-1 pr-24"
                phx-hook="ClearInput"
              />
              <div class="absolute right-2 top-1/2 -translate-y-1/2 flex gap-1">
                <.button
                  type="button"
                  variant="ghost"
                  size="icon-sm"
                  phx-hook="EmojiPicker"
                  id="emoji-trigger"
                >
                  <.icon name="tabler-mood-smile" class="w-4 h-4" />
                </.button>
              </div>
            </div>
            <.button type="submit" size="icon">
              <.icon name="tabler-send" class="w-4 h-4" />
            </.button>
          </form>
          <!-- Add the emoji picker element (hidden by default) -->
          <div id="emoji-picker-container" class="hidden absolute bottom-[80px] right-4">
            <emoji-picker></emoji-picker>
          </div>
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
                      Payout amount (<%= @timesheet.hours_worked %> hours x <%= Money.to_string!(
                        @contract.hourly_rate
                      ) %>/hr)
                    </dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.to_string!(calculate_amount(@contract, @timesheet)) %>
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
                  <div class="h-5"></div>
                  <div class="h-px bg-border" />
                  <div class="flex justify-between">
                    <dt class="font-medium">Total Due</dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.to_string!(
                        Money.sub!(calculate_amount(@contract, @timesheet), @escrow_amount)
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
                          if Money.compare!(@fee_data.total_paid, tier.threshold) != :lt do
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
                        <%= Money.to_string!(tier.threshold) %>
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
                    <%= Money.to_string!(@fee_data.total_paid) %>
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
                      Renewal amount (<%= @contract.hours_per_week %> hours x <%= Money.to_string!(
                        @contract.hourly_rate
                      ) %>/hr)
                    </dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.to_string!(@escrow_amount) %>
                    </dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">
                      Algora fees (<%= @fee_data.fee_percentage %>%)
                    </dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.to_string!(
                        Money.mult!(
                          @escrow_amount,
                          Decimal.div(Decimal.new(@fee_data.fee_percentage), Decimal.new(100))
                        )
                      ) %>
                    </dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">Transaction fees (4%)</dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.to_string!(
                        Money.mult!(
                          @escrow_amount,
                          Decimal.new("0.04")
                        )
                      ) %>
                    </dd>
                  </div>
                  <div class="h-px bg-border" />
                  <div class="flex justify-between">
                    <dt class="font-medium">Total Due</dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.to_string!(
                        Money.mult!(
                          @escrow_amount,
                          Decimal.add(
                            Decimal.div(Decimal.new(@fee_data.fee_percentage), Decimal.new(100)),
                            Decimal.new("1.04")
                          )
                        )
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
                      <%= Money.to_string!(calculate_amount(@contract, @timesheet)) %>
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
                        Money.sub!(calculate_amount(@contract, @timesheet), @escrow_amount)
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
                      <%= Money.to_string!(@escrow_amount) %>
                    </dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">Contract Period</dt>
                    <dd class="font-semibold">
                      <%= Calendar.strftime(@contract.start_date, "%b %d") %> - <%= Calendar.strftime(
                        @contract.end_date,
                        "%b %d, %Y"
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

    # Get all contracts in the chain
    contracts = get_contract_chain(contract)

    # Calculate total paid from all transfers across the contract chain
    total_paid =
      contracts
      |> Enum.flat_map(& &1.transactions)
      |> Enum.filter(&(&1.type == :transfer))
      |> Enum.reduce(Money.zero(:USD), &Money.add!(&2, &1.amount))

    timesheet = get_latest_timesheet(contract)

    latest_charge =
      contract.transactions
      |> Enum.filter(&(&1.type == :charge))
      |> Enum.sort_by(& &1.inserted_at, :desc)
      |> List.first()

    {:ok, thread} = get_or_create_thread(contract)
    messages = Chat.list_messages(thread.id) |> Repo.preload(:sender)

    {:ok,
     socket
     # Update the contract's total_paid
     |> assign(:contract, %{contract | total_paid: total_paid})
     |> assign(:timesheet, timesheet)
     |> assign(:latest_charge, latest_charge)
     |> assign(:escrow_amount, calculate_escrow_amount(contract))
     |> assign(:page_title, "Contract with #{contract.provider.name}")
     |> assign(:messages, messages)
     |> assign(:thread, thread)
     |> assign(:show_release_renew_modal, false)
     |> assign(:show_release_modal, false)
     |> assign(:show_dispute_modal, false)
     |> assign(:fee_data, calculate_fee_data(contract))
     |> assign(:org_members, Organizations.list_org_members(contract.client))
     |> assign(:tech_stack, ["Python", "AWS", "React", "Node.js"])}
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

    {:noreply,
     socket
     |> update(:messages, &(&1 ++ [message]))
     |> push_event("clear-input", %{selector: "#message-input"})}
  end

  def handle_event("show_release_modal", %{"contract_id" => _contract_id}, socket) do
    {:noreply, assign(socket, :show_release_modal, true)}
  end

  def handle_event("show_dispute_modal", %{"contract_id" => _contract_id}, socket) do
    {:noreply, assign(socket, :show_dispute_modal, true)}
  end

  def handle_event("show_release_renew_modal", %{"contract_id" => _contract_id}, socket) do
    {:noreply, assign(socket, :show_release_renew_modal, true)}
  end

  def handle_event("close_drawer", _, socket) do
    {:noreply,
     socket
     |> assign(:show_release_modal, false)
     |> assign(:show_release_renew_modal, false)
     |> assign(:show_dispute_modal, false)}
  end

  def handle_event("release_payment", %{"feedback" => feedback}, socket) do
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

    {:noreply,
     socket
     |> assign(:show_release_modal, false)
     |> put_flash(:info, "Payment released successfully")}
  end

  def handle_event("raise_dispute", %{"reason" => _reason}, socket) do
    # Add dispute handling logic here

    {:noreply,
     socket
     |> assign(:show_dispute_modal, false)
     |> put_flash(:info, "Dispute raised successfully")}
  end

  defp get_or_create_thread(contract) do
    case Chat.get_thread_for_users(contract.client_id, contract.provider_id) do
      nil -> Chat.create_direct_thread(contract.client, contract.provider)
      thread -> {:ok, thread}
    end
  end

  defp calculate_fee_data(contract) do
    # Get all contracts in the chain
    contracts = get_contract_chain(contract)

    # Calculate total paid from all transfers
    total_paid =
      contracts
      |> Enum.flat_map(& &1.transactions)
      |> Enum.filter(&(&1.type == :transfer))
      |> Enum.reduce(Money.zero(:USD), &Money.add!(&2, &1.amount))

    fee_tiers = [
      %{threshold: Money.zero(:USD), fee: 19},
      %{threshold: Money.new!(3000, :USD), fee: 15},
      %{threshold: Money.new!(5000, :USD), fee: 10},
      %{threshold: Money.new!(15000, :USD), fee: 5}
    ]

    %{
      total_paid: total_paid,
      fee_tiers: fee_tiers,
      fee_percentage: calculate_fee_percentage(total_paid),
      progress: calculate_progress(total_paid)
    }
  end

  defp calculate_fee_percentage(total_paid) do
    cond do
      Money.compare!(total_paid, Money.new!(15000, :USD)) != :lt -> 5
      Money.compare!(total_paid, Money.new!(5000, :USD)) != :lt -> 10
      Money.compare!(total_paid, Money.new!(3000, :USD)) != :lt -> 15
      true -> 19
    end
  end

  defp calculate_progress(total_paid) do
    tiers = [
      {Money.new!(3000, :USD), 33.3},
      {Money.new!(5000, :USD), 66.6},
      {Money.new!(15000, :USD), 100.0}
    ]

    first_tier = Money.new!(3000, :USD)

    case Enum.find(tiers, fn {threshold, _} -> Money.compare!(total_paid, threshold) == :lt end) do
      nil ->
        100.0

      {^first_tier, max_percent} ->
        percentage_of(total_paid, first_tier) * max_percent

      {threshold, max_percent} ->
        {prev_threshold, prev_percent} = get_previous_tier(tiers, threshold)

        progress_in_tier =
          percentage_of(
            Money.sub!(total_paid, prev_threshold),
            Money.sub!(threshold, prev_threshold)
          )

        prev_percent + progress_in_tier * (max_percent - prev_percent)
    end
  end

  defp percentage_of(amount, total) do
    amount
    |> Money.to_decimal()
    |> Decimal.div(Money.to_decimal(total))
    |> Decimal.to_float()
  end

  defp get_previous_tier(tiers, threshold) do
    tiers
    |> Enum.reduce_while(nil, fn tier = {amount, _}, acc ->
      if Money.equal?(amount, threshold), do: {:halt, acc}, else: {:cont, tier}
    end)
  end

  defp get_contract_chain(contract) do
    case contract.original_contract_id do
      nil -> [contract | contract.renewals]
      _ -> [contract.original_contract | contract.original_contract.renewals]
    end
    |> Enum.uniq_by(& &1.id)
    |> Enum.sort_by(& &1.start_date, {:desc, DateTime})
  end

  defp get_payment_status(contract) do
    case {get_latest_timesheet(contract), get_latest_transaction(contract)} do
      {nil, _} ->
        nil

      {timesheet, transaction} ->
        cond do
          transaction.type == :transfer -> {:completed, timesheet, transaction}
          transaction.type == :charge -> {:pending_release, timesheet}
          transaction.type == :refund -> {:refunded, timesheet}
        end
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
    Money.mult!(contract.hourly_rate, timesheet.hours_worked)
  end

  defp calculate_escrow_amount(contract) do
    # Get all contracts in the chain
    contracts = get_contract_chain(contract)

    # Sum all charges across all contracts
    total_charged =
      contracts
      |> Enum.flat_map(& &1.transactions)
      |> Enum.filter(&(&1.type == :charge))
      |> Enum.reduce(Money.zero(:USD), &Money.add!(&2, &1.amount))

    # Sum all transfers across all contracts
    total_transferred =
      contracts
      |> Enum.flat_map(& &1.transactions)
      |> Enum.filter(&(&1.type == :transfer))
      |> Enum.reduce(Money.zero(:USD), &Money.add!(&2, &1.amount))

    Money.sub!(total_charged, total_transferred)
  end

  defp get_contract_activity(contract) do
    # Get all contracts in the chain ordered by start date (oldest first)
    contracts =
      get_contract_chain(contract)
      |> Enum.sort_by(& &1.start_date, :asc)

    # Build timeline by processing each contract period sequentially
    contracts
    |> Enum.with_index()
    |> Enum.flat_map(fn {contract, index} ->
      [
        # 0. Initial escrow charge
        contract.transactions
        |> Enum.filter(&(&1.type == :charge))
        |> Enum.map(fn transaction ->
          %{
            type: :escrow,
            description: "Payment escrowed: #{Money.to_string!(transaction.amount)}",
            date: transaction.inserted_at,
            amount: transaction.amount
          }
        end),

        # 1. Contract start
        if(index != 0) do
          %{
            type: :renewal,
            description: "Contract renewed for another period",
            date: contract.inserted_at,
            amount: nil
          }
        end,

        # 2. Timesheet submissions
        contract.timesheets
        |> Enum.sort_by(& &1.inserted_at)
        |> Enum.map(fn timesheet ->
          %{
            type: :timesheet,
            description: "Timesheet submitted for #{timesheet.hours_worked} hours",
            date: timesheet.inserted_at,
            amount: calculate_amount(contract, timesheet)
          }
        end),

        # 3. Payment releases (transfers)
        contract.transactions
        |> Enum.filter(&(&1.type == :transfer))
        |> Enum.sort_by(& &1.inserted_at)
        |> Enum.map(fn transaction ->
          %{
            type: :release,
            description: "Payment released: #{Money.to_string!(transaction.amount)}",
            date: transaction.inserted_at,
            amount: transaction.amount
          }
        end)
      ]
      |> List.flatten()
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1.date, {:desc, DateTime})
  end

  defp timeline_activity(assigns) do
    ~H"""
    <div class="flex items-center gap-4">
      <div class={[
        "h-9 w-9 rounded-full flex items-center justify-center",
        activity_background_class(@activity.type)
      ]}>
        <.icon name={activity_icon(@activity.type)} class="w-5 h-5" />
      </div>
      <div class="flex-1">
        <div class="font-medium">
          <%= @activity.description %>
        </div>
        <div class="text-sm text-muted-foreground">
          <%= Calendar.strftime(@activity.date, "%b %d, %Y, %H:%M:%S") %>
        </div>
      </div>
    </div>
    """
  end

  defp activity_icon(type) do
    case type do
      :signed -> "tabler-file-check"
      :timesheet -> "tabler-clock"
      :escrow -> "tabler-wallet"
      :release -> "tabler-cash"
      :refund -> "tabler-arrow-back"
      :renewal -> "tabler-refresh"
    end
  end

  defp activity_background_class(type) do
    case type do
      :signed -> "bg-primary/20"
      :timesheet -> "bg-warning/20"
      :escrow -> "bg-info/20"
      :release -> "bg-success/20"
      :refund -> "bg-destructive/20"
      :renewal -> "bg-primary/20"
    end
  end
end
