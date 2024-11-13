defmodule AlgoraWeb.Contract.ViewLive do
  use AlgoraWeb, :live_view
  alias Algora.Accounts
  alias Algora.Money
  alias Algora.Organizations

  def mount(%{"id" => id}, _session, socket) do
    company = Organizations.get_org_by_handle!("algora")

    developer =
      Accounts.list_matching_devs(limit: 20, skills: ["Elixir", "Phoenix"])
      |> Enum.at(8)
      |> Map.merge(%{
        timezone: "PST (UTC-8)",
        location: "Vancouver, Canada",
        availability: "Available for work",
        rate: "$120/hr",
        skills: ["Elixir", "Phoenix", "React", "TypeScript", "PostgreSQL"],
        socials: [
          %{name: "GitHub", url: "https://github.com/dev123", icon: "tabler-brand-github"},
          %{name: "Twitter", url: "https://twitter.com/dev123", icon: "tabler-brand-twitter"},
          %{
            name: "LinkedIn",
            url: "https://linkedin.com/in/dev123",
            icon: "tabler-brand-linkedin"
          },
          %{name: "Website", url: "https://dev123.com", icon: "tabler-world"}
        ]
      })

    contract = %{
      id: id,
      status: :active,
      start_date: ~D[2024-03-01],
      hourly_rate: Decimal.new(75),
      hours_per_week: 20,
      total_paid: Decimal.new(3000),
      escrow_amount: Decimal.new(1500),
      next_payment: ~D[2024-03-22],
      company: company,
      developer: developer,
      payment_history: [
        %{
          date: ~D[2024-03-15],
          amount: Decimal.new(1500),
          hours: 20,
          status: :completed
        },
        %{
          date: ~D[2024-03-08],
          amount: Decimal.new(1500),
          hours: 20,
          status: :completed
        },
        %{
          date: ~D[2024-03-01],
          amount: Decimal.new(1500),
          hours: 20,
          status: :completed
        }
      ]
    }

    # Add chat messages setup
    messages = [
      %{
        id: 1,
        sender: socket.assigns.current_user,
        content:
          "yo! saw you've worked with Phoenix LiveView before. we're building a real-time collab tool and could use your expertise",
        sent_at: "11:30 AM",
        date: "Monday",
        is_self: true,
        avatar_url: socket.assigns.current_user.avatar_url
      },
      %{
        id: 2,
        sender: contract.developer,
        content:
          "hey! yeah I've built a few things with LiveView. what kind of collab tool are you working on?",
        sent_at: "11:45 AM",
        date: "Monday",
        is_self: false,
        avatar_url: contract.developer.avatar_url
      },
      %{
        id: 3,
        sender: socket.assigns.current_user,
        content:
          "it's like figma but for devs - shared coding environment with real-time cursors, chat, etc. biggest challenge right now is handling presence with 1000+ concurrent users",
        sent_at: "2:30 PM",
        date: "Monday",
        is_self: true,
        avatar_url: socket.assigns.current_user.avatar_url
      },
      %{
        id: 4,
        sender: contract.developer,
        content:
          "oh nice! yeah Phoenix Presence would work well for that. I did something similar with LiveView for a collaborative whiteboard. had to do some tricks with debouncing to handle the cursor updates efficiently",
        sent_at: "3:15 PM",
        date: "Monday",
        is_self: false,
        avatar_url: contract.developer.avatar_url
      },
      %{
        id: 5,
        sender: socket.assigns.current_user,
        content:
          "that's exactly what we need! mind taking a look at our presence.ex module? getting some weird race conditions when users disconnect",
        sent_at: "9:30 AM",
        date: "Yesterday",
        is_self: true,
        avatar_url: socket.assigns.current_user.avatar_url
      },
      %{
        id: 6,
        sender: contract.developer,
        content:
          "sure, drop a gist link. also check out :pg2 vs :pg - we had to switch because of similar issues at scale",
        sent_at: "9:45 AM",
        date: "Yesterday",
        is_self: false,
        avatar_url: contract.developer.avatar_url
      },
      %{
        id: 7,
        sender: socket.assigns.current_user,
        content:
          "awesome, here's the gist: https://gist.github.com/... also curious how you handled the pubsub sharding",
        sent_at: "10:15 AM",
        date: "Yesterday",
        is_self: true,
        avatar_url: socket.assigns.current_user.avatar_url
      },
      %{
        id: 8,
        sender: contract.developer,
        content:
          "for pubsub we ended up using Redis as a backend with multiple nodes. I can share our config later today",
        sent_at: "10:30 AM",
        date: "Yesterday",
        is_self: false,
        avatar_url: contract.developer.avatar_url
      },
      %{
        id: 9,
        sender: socket.assigns.current_user,
        content: "that would be super helpful! we're hitting similar scaling issues",
        sent_at: "11:00 AM",
        date: "Yesterday",
        is_self: true,
        avatar_url: socket.assigns.current_user.avatar_url
      },
      %{
        id: 10,
        sender: contract.developer,
        content: "here's our Redis setup: [code snippet]. we're using clustering with 3 nodes",
        sent_at: "2:30 PM",
        date: "Yesterday",
        is_self: false,
        avatar_url: contract.developer.avatar_url
      },
      %{
        id: 11,
        sender: socket.assigns.current_user,
        content: "this looks great! one question about the failover configuration...",
        sent_at: "3:00 PM",
        date: "Yesterday",
        is_self: true,
        avatar_url: socket.assigns.current_user.avatar_url
      },
      %{
        id: 12,
        sender: contract.developer,
        content:
          "we're using Redis Sentinel for that. it automatically handles primary node election",
        sent_at: "3:15 PM",
        date: "Yesterday",
        is_self: false,
        avatar_url: contract.developer.avatar_url
      },
      %{
        id: 13,
        sender: socket.assigns.current_user,
        content:
          "morning! got those changes implemented and the presence system is much more stable now",
        sent_at: "9:00 AM",
        date: "Today",
        is_self: true,
        avatar_url: socket.assigns.current_user.avatar_url
      },
      %{
        id: 14,
        sender: contract.developer,
        content:
          "great to hear! what kind of improvement are you seeing in terms of connection handling?",
        sent_at: "9:15 AM",
        date: "Today",
        is_self: false,
        avatar_url: contract.developer.avatar_url
      },
      %{
        id: 15,
        sender: socket.assigns.current_user,
        content: "massive difference - went from ~70% successful reconnects to 99%+",
        sent_at: "9:30 AM",
        date: "Today",
        is_self: true,
        avatar_url: socket.assigns.current_user.avatar_url
      }
    ]

    {:ok,
     socket
     |> assign(:contract, contract)
     |> assign(:page_title, "#{contract.developer.name} <> #{contract.company.name}")
     |> assign(:messages, messages)}
  end

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
                  <.avatar_image src={@contract.company.avatar_url} />
                  <.avatar_fallback>
                    <%= String.slice(@contract.company.name, 0, 2) %>
                  </.avatar_fallback>
                </.avatar>
                <.avatar class="h-12 w-12 ring-2 ring-background">
                  <.avatar_image src={@contract.developer.avatar_url} />
                  <.avatar_fallback>
                    <%= String.slice(@contract.developer.name, 0, 2) %>
                  </.avatar_fallback>
                </.avatar>
              </div>
              <div>
                <h1 class="text-2xl font-semibold">
                  Contract with <%= @contract.developer.name %>
                </h1>
                <p class="text-sm text-muted-foreground">
                  Started <%= Calendar.strftime(@contract.start_date, "%B %d, %Y") %>
                </p>
              </div>
            </div>
            <div>
              <.badge variant="success">Active</.badge>
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
                  <%= Money.format!(@contract.escrow_amount, "USD") %>
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
                    <!-- Upcoming Payment -->
                    <div class="-mx-4 flex items-center justify-between bg-muted/30 p-4 rounded-lg">
                      <div class="flex items-center gap-4">
                        <div class="h-9 w-9 rounded-full bg-primary/20 flex items-center justify-center">
                          <.icon name="tabler-clock" class="w-5 h-5 text-primary" />
                        </div>
                        <div>
                          <div class="font-medium">
                            Upcoming payment for 20 hours
                          </div>
                          <div class="text-sm text-muted-foreground">
                            <%= Calendar.strftime(@contract.next_payment, "%B %d, %Y") %>
                          </div>
                        </div>
                      </div>
                      <div class="flex items-center gap-2">
                        <div class="text-right mr-4">
                          <div class="font-medium font-display">
                            <%= Money.format!(@contract.escrow_amount, "USD") %>
                          </div>
                          <div class="text-sm text-muted-foreground">
                            Pending
                          </div>
                        </div>

                        <div class="flex items-center gap-2">
                          <.button>
                            Release & Renew
                          </.button>

                          <.dropdown_menu>
                            <.dropdown_menu_trigger>
                              <.button variant="ghost" size="icon">
                                <.icon name="tabler-dots-vertical" class="w-4 h-4" />
                              </.button>
                            </.dropdown_menu_trigger>
                            <.dropdown_menu_content class="w-56 rounded-md border bg-popover p-1 shadow-md">
                              <div class="px-2 py-1.5 text-sm cursor-pointer hover:bg-muted rounded-sm flex items-center">
                                <.icon name="tabler-arrow-right" class="w-4 h-4 mr-2" />
                                Release without renew
                              </div>
                              <div class="h-px bg-border my-1" />
                              <div class="px-2 py-1.5 text-sm cursor-pointer hover:bg-muted rounded-sm flex items-center text-destructive">
                                <.icon name="tabler-alert-triangle" class="w-4 h-4 mr-2" /> Dispute
                              </div>
                            </.dropdown_menu_content>
                          </.dropdown_menu>
                        </div>
                      </div>
                    </div>
                    <!-- Past Payments -->
                    <%= for payment <- @contract.payment_history do %>
                      <div class="flex items-center justify-between">
                        <div class="flex items-center gap-4">
                          <div class="h-9 w-9 rounded-full bg-muted flex items-center justify-center">
                            <.icon name="tabler-credit-card" class="w-5 h-5" />
                          </div>
                          <div>
                            <div class="font-medium">
                              Payment for <%= payment.hours %> hours
                            </div>
                            <div class="text-sm text-muted-foreground">
                              <%= Calendar.strftime(payment.date, "%B %d, %Y") %>
                            </div>
                          </div>
                        </div>
                        <div class="text-right">
                          <div class="font-medium font-display">
                            <%= Money.format!(payment.amount, "USD") %>
                          </div>
                          <div class="text-sm text-muted-foreground">
                            <%= String.capitalize(to_string(payment.status)) %>
                          </div>
                        </div>
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
                    <.card_title>Company</.card_title>
                  </.card_header>
                  <.card_content>
                    <div class="flex items-center gap-4">
                      <.avatar class="h-16 w-16">
                        <.avatar_image src={@contract.company.avatar_url} />
                      </.avatar>
                      <div>
                        <div class="font-medium text-lg"><%= @contract.company.name %></div>
                        <div class="text-sm text-muted-foreground">
                          @<%= @contract.company.handle %>
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
                          <.avatar_image src={@contract.developer.avatar_url} />
                        </.avatar>
                        <div>
                          <div class="font-medium text-lg"><%= @contract.developer.name %></div>
                          <div class="text-sm text-muted-foreground">
                            @<%= @contract.developer.handle %>
                          </div>
                        </div>
                      </div>

                      <div class="pt-4 space-y-2">
                        <div class="flex items-center gap-2 text-sm text-muted-foreground">
                          <.icon name="tabler-map-pin" class="w-4 h-4" />
                          <%= @contract.developer.location %>
                        </div>
                        <div class="flex items-center gap-2 text-sm text-muted-foreground">
                          <.icon name="tabler-clock" class="w-4 h-4" />
                          <%= @contract.developer.timezone %>
                        </div>
                      </div>

                      <div class="flex flex-wrap gap-2 pt-2">
                        <%= for skill <- @contract.developer.skills do %>
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
                <.avatar_image src={@contract.developer.avatar_url} alt="Developer avatar" />
                <.avatar_fallback>
                  <%= String.slice(@contract.developer.name, 0, 2) %>
                </.avatar_fallback>
              </.avatar>
              <div class="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-success border-2 border-background">
              </div>
            </div>
            <div>
              <h2 class="text-lg font-semibold"><%= @contract.developer.name %></h2>
              <p class="text-xs text-muted-foreground">Active now</p>
            </div>
          </div>
        </div>

        <.scroll_area
          class="flex-1 p-4 flex flex-col-reverse h-full"
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
    """
  end

  def handle_event("send_message", %{"message" => content}, socket) do
    new_message = %{
      id: System.unique_integer([:positive]),
      sender: socket.assigns.current_user,
      content: content,
      sent_at: Time.utc_now() |> Time.to_string() |> String.slice(0..4),
      date: "Today",
      is_self: true,
      avatar_url: socket.assigns.current_user.avatar_url
    }

    {:noreply, update(socket, :messages, &(&1 ++ [new_message]))}
  end
end
