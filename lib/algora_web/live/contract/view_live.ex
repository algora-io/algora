defmodule AlgoraWeb.Contract.ViewLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Chat
  alias Algora.Contracts
  alias Algora.Contracts.Contract
  alias Algora.Organizations
  alias Algora.Repo

  defp page_size, do: 10

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
                    {String.slice(@contract.client.name, 0, 2)}
                  </.avatar_fallback>
                </.avatar>
                <.avatar class="h-12 w-12 ring-2 ring-background">
                  <.avatar_image src={@contract.contractor.avatar_url} />
                  <.avatar_fallback>
                    {String.slice(@contract.contractor.name, 0, 2)}
                  </.avatar_fallback>
                </.avatar>
              </div>
              <div>
                <h1 class="text-2xl font-semibold">
                  Contract with {@contract.contractor.name}
                </h1>
                <p class="text-sm text-muted-foreground">
                  Started {Calendar.strftime(@contract.start_date, "%b %d, %Y")}
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
                  {Money.to_string!(@contract.hourly_rate)}/hr
                </div>
              </.card_content>
            </.card>

            <.card>
              <.card_content class="pt-6">
                <div class="text-sm text-muted-foreground mb-2">Hours per week</div>
                <div class="text-2xl font-semibold font-display">
                  {@contract.hours_per_week}
                </div>
              </.card_content>
            </.card>
            <.card>
              <.card_content class="pt-6">
                <div class="text-sm text-muted-foreground mb-2">In escrow</div>
                <div class="text-2xl font-semibold font-display">
                  {Money.to_string!(Contract.balance(@contract))}
                </div>
              </.card_content>
            </.card>
            <.card>
              <.card_content class="pt-6">
                <div class="text-sm text-muted-foreground mb-2">Total paid</div>
                <div class="text-2xl font-semibold font-display">
                  {Money.to_string!(@contract.total_credited)}
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
                    <%= for contract <- @contract_chain do %>
                      <%= case Contracts.get_payment_status(contract) do %>
                        <% {:pending_timesheet, contract} -> %>
                          <div class="flex items-center justify-between">
                            <div class="flex items-center gap-4">
                              <div class="h-9 w-9 rounded-full bg-warning/20 flex items-center justify-center">
                                <.icon name="tabler-clock" class="w-5 h-5 text-warning" />
                              </div>
                              <div>
                                <div class="font-medium">
                                  Waiting for timesheet submission
                                </div>
                                <div class="text-sm text-muted-foreground">
                                  {Calendar.strftime(contract.start_date, "%b %d")} - {Calendar.strftime(
                                    contract.end_date,
                                    "%b %d, %Y"
                                  )}
                                </div>
                              </div>
                            </div>
                            <div class="text-right">
                              <div class="font-medium font-display">Pending</div>
                              <div class="text-sm text-muted-foreground">Timesheet</div>
                            </div>
                          </div>
                        <% {:pending_release, contract} -> %>
                          <div class="-mx-4 flex items-center justify-between bg-muted/30 p-4 rounded-lg">
                            <div class="flex items-center gap-4">
                              <div class="h-9 w-9 rounded-full bg-primary/20 flex items-center justify-center">
                                <.icon name="tabler-clock" class="w-5 h-5 text-primary" />
                              </div>
                              <div>
                                <div class="font-medium">
                                  Ready to release payment for {contract.timesheet.hours_worked} hours
                                </div>
                                <div class="text-sm text-muted-foreground">
                                  {Calendar.strftime(contract.start_date, "%b %d")} - {Calendar.strftime(
                                    contract.end_date,
                                    "%b %d, %Y"
                                  )}
                                </div>
                              </div>
                            </div>
                            <div class="flex items-center gap-2">
                              <div class="text-right mr-4">
                                <div class="font-medium font-display">
                                  {Money.to_string!(Contracts.calculate_transfer_amount(contract))}
                                </div>
                                <div class="text-sm text-muted-foreground">
                                  Ready to Release
                                </div>
                              </div>

                              <div class="flex items-center gap-2">
                                <.button phx-click="show_release_renew_modal">
                                  Release & Renew
                                </.button>

                                <.dropdown_menu>
                                  <.dropdown_menu_trigger>
                                    <.button variant="ghost" size="icon">
                                      <.icon name="tabler-dots-vertical" class="w-4 h-4" />
                                    </.button>
                                  </.dropdown_menu_trigger>
                                  <.dropdown_menu_content>
                                    <.dropdown_menu_item phx-click="show_release_modal">
                                      <.icon name="tabler-arrow-right" class="w-4 h-4 mr-2" />
                                      Release without renew
                                    </.dropdown_menu_item>
                                    <.dropdown_menu_separator />
                                    <.dropdown_menu_item
                                      phx-click="show_dispute_modal"
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
                        <% {:paid, contract} -> %>
                          <div class="flex items-center justify-between">
                            <div class="flex items-center gap-4">
                              <div class="h-9 w-9 rounded-full bg-success/20 flex items-center justify-center">
                                <.icon name="tabler-check" class="w-5 h-5 text-success" />
                              </div>
                              <div>
                                <div class="font-medium">
                                  Payment for {contract.timesheet.hours_worked} hours
                                </div>
                                <div class="text-sm text-muted-foreground">
                                  {Calendar.strftime(contract.start_date, "%b %d")} - {Calendar.strftime(
                                    contract.end_date,
                                    "%b %d, %Y"
                                  )}
                                </div>
                              </div>
                            </div>
                            <div class="text-right">
                              <div class="font-medium font-display">
                                {Money.to_string!(contract.amount_credited)}
                              </div>
                              <div class="text-sm text-muted-foreground">Paid</div>
                            </div>
                          </div>
                      <% end %>
                    <% end %>

                    <%= if @has_more do %>
                      <div class="flex justify-center">
                        <.button variant="ghost" phx-click="load_more">
                          <.icon name="tabler-arrow-down" class="w-4 h-4 mr-2" /> Load More
                        </.button>
                      </div>
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
                        <div class="font-medium text-lg">{@contract.client.name}</div>
                        <div class="text-sm text-muted-foreground">
                          @{@contract.client.handle}
                        </div>
                      </div>
                    </div>
                    <div class="pt-6 flex flex-wrap gap-2">
                      <%= for tech <- @contract.client.tech_stack do %>
                        <span class="rounded-lg px-2 py-0.5 text-xs ring-1 ring-border bg-secondary">
                          {tech}
                        </span>
                      <% end %>
                    </div>
                    <div class="pt-6 flex -space-x-1">
                      <%= for member <- @org_members do %>
                        <.avatar class="h-9 w-9 ring-2 ring-background">
                          <.avatar_image src={member.avatar_url} />
                          <.avatar_fallback>
                            {String.slice(member.name, 0, 2)}
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
                        <.avatar_image src={@contract.contractor.avatar_url} />
                      </.avatar>
                      <div>
                        <div class="font-medium text-lg">{@contract.contractor.name}</div>
                        <div class="text-sm text-muted-foreground">
                          @{@contract.contractor.handle}
                        </div>
                      </div>
                    </div>
                    <div class="pt-6 flex flex-wrap gap-2">
                      <%= for tech <- @contract.contractor.tech_stack do %>
                        <span class="rounded-lg px-2 py-0.5 text-xs ring-1 ring-border bg-secondary">
                          {tech}
                        </span>
                      <% end %>
                    </div>
                    <div class="pt-6 space-y-2">
                      <div class="flex items-center gap-2 text-sm text-muted-foreground">
                        <.icon name="tabler-map-pin" class="w-4 h-4" />
                        {@contract.contractor.location}
                      </div>
                      <%= if @contract.contractor.timezone do %>
                        <div class="flex items-center gap-2 text-sm text-muted-foreground">
                          <.icon name="tabler-clock" class="w-4 h-4" />
                          {Algora.Time.friendly_timezone(@contract.contractor.timezone)}
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
                    <%= for activity <- Contracts.build_contract_timeline(@contract_chain) do %>
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
                <.avatar_image src={@contract.contractor.avatar_url} alt="Developer avatar" />
                <.avatar_fallback>
                  {String.slice(@contract.contractor.name, 0, 2)}
                </.avatar_fallback>
              </.avatar>
              <div class="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-success border-2 border-background">
              </div>
            </div>
            <div>
              <h2 class="text-lg font-semibold">{@contract.contractor.name}</h2>
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
                |> Enum.sort_by(fn {_, msgs} -> hd(msgs).inserted_at end, Date) do %>
              <div class="flex items-center justify-center">
                <div class="text-xs text-muted-foreground bg-background px-2 py-1 rounded-full">
                  {date}
                </div>
              </div>

              <div class="flex flex-col gap-6">
                <%= for message <- Enum.sort_by(messages, & &1.inserted_at, Date) do %>
                  <div class="flex gap-3 group">
                    <.avatar class="h-8 w-8">
                      <.avatar_image src={message.sender.avatar_url} />
                      <.avatar_fallback>
                        {String.slice(message.sender.name, 0, 2)}
                      </.avatar_fallback>
                    </.avatar>
                    <div class="relative max-w-[80%] rounded-2xl p-3 bg-muted rounded-tl-none">
                      {message.content}
                      <div class="text-[10px] mt-1 text-muted-foreground">
                        {message.inserted_at
                        |> DateTime.to_time()
                        |> Time.to_string()
                        |> String.slice(0..4)}
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
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

    <.live_component
      :if={@contract.timesheet}
      module={AlgoraWeb.Contract.Modals.ReleaseRenewDrawer}
      id="release-renew-drawer"
      show={@show_release_renew_modal}
      on_cancel="close_drawer"
      contract={@contract}
      fee_data={@fee_data}
    />

    <.live_component
      :if={@contract.timesheet}
      module={AlgoraWeb.Contract.Modals.ReleaseDrawer}
      id="release-drawer"
      show={@show_release_modal}
      on_cancel="close_drawer"
      contract={@contract}
    />

    <.live_component
      module={AlgoraWeb.Contract.Modals.DisputeDrawer}
      id="dispute-drawer"
      show={@show_dispute_modal}
      on_cancel="close_drawer"
      contract={@contract}
    />
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    {:ok, contract} = Contracts.fetch_last_contract(id)
    contract_chain = Contracts.list_contract_chain(original_contract_id: id, limit: page_size())
    thread = Chat.get_or_create_thread!(contract)
    messages = thread.id |> Chat.list_messages() |> Repo.preload(:sender)

    {:ok,
     socket
     |> assign(:contract, contract)
     |> assign(:contract_chain, contract_chain)
     |> assign(:has_more, length(contract_chain) >= page_size())
     |> assign(:page_title, "Contract with #{contract.contractor.name}")
     |> assign(:messages, messages)
     |> assign(:thread, thread)
     |> assign(:show_release_renew_modal, false)
     |> assign(:show_release_modal, false)
     |> assign(:show_dispute_modal, false)
     |> assign(:fee_data, Contracts.calculate_fee_data(contract))
     |> assign(:org_members, Organizations.list_org_members(contract.client))}
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

  def handle_event("close_drawer", _, socket) do
    {:noreply,
     socket
     |> assign(:show_release_modal, false)
     |> assign(:show_release_renew_modal, false)
     |> assign(:show_dispute_modal, false)}
  end

  def handle_event("show_release_modal", _params, socket) do
    {:noreply, assign(socket, :show_release_modal, true)}
  end

  def handle_event("show_dispute_modal", _params, socket) do
    {:noreply, assign(socket, :show_dispute_modal, true)}
  end

  def handle_event("show_release_renew_modal", _params, socket) do
    {:noreply, assign(socket, :show_release_renew_modal, true)}
  end

  def handle_event("load_more", _params, socket) do
    %{contract_chain: contract_chain} = socket.assigns

    more_items =
      Contracts.list_contract_chain(
        original_contract_id: socket.assigns.contract.original_contract_id,
        before: List.last(contract_chain).sequence_number,
        limit: page_size()
      )

    {:noreply,
     socket
     |> assign(:contract_chain, contract_chain ++ more_items)
     |> assign(:has_more, length(more_items) >= page_size())}
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
          {@activity.description}
        </div>
        <div class="text-sm text-muted-foreground">
          {Calendar.strftime(@activity.date, "%b %d, %Y, %H:%M:%S")}
        </div>
      </div>
    </div>
    """
  end

  defp activity_icon(type) do
    case type do
      :signed -> "tabler-file-check"
      :timesheet -> "tabler-clock"
      :prepayment -> "tabler-wallet"
      :release -> "tabler-cash"
      :reversal -> "tabler-arrow-back"
      :renewal -> "tabler-refresh"
    end
  end

  defp activity_background_class(type) do
    case type do
      :signed -> "bg-primary/20"
      :timesheet -> "bg-warning/20"
      :prepayment -> "bg-info/20"
      :release -> "bg-success/20"
      :reversal -> "bg-destructive/20"
      :renewal -> "bg-primary/20"
    end
  end
end
