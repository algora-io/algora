defmodule AlgoraWeb.ChatLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Users

  def mount(_params, _session, socket) do
    # Get current user details
    current_user = socket.assigns.current_user

    # Get all matching devs for the sidebar
    matching_devs = Users.list_developers(limit: 20, sort_by_tech_stack: ["Elixir", "Phoenix"])

    # In mount function, create static chat histories
    chat_histories = [
      %{
        last_message: "The websocket connection pooling looks good now",
        timestamp: "2m",
        unread: true
      },
      %{
        last_message: "Could you review my PR for the auth middleware?",
        timestamp: "15m",
        unread: false
      },
      %{
        last_message: "Thanks for helping debug that race condition!",
        timestamp: "45m",
        unread: false
      },
      %{
        last_message: "Let's sync about the k8s deployment tomorrow",
        timestamp: "1h",
        unread: true
      },
      %{
        last_message: "The new component library is ready for review",
        timestamp: "3h",
        unread: false
      },
      %{
        last_message: "Just pushed fixes for the GraphQL pagination",
        timestamp: "5h",
        unread: false
      },
      %{
        last_message: "Can you help me with some Elixir pattern matching?",
        timestamp: "8h",
        unread: false
      },
      %{
        last_message: "Docker build is failing on M1 Macs - any ideas?",
        timestamp: "12h",
        unread: true
      },
      %{
        last_message: "Updated the API docs with the new endpoints",
        timestamp: "1d",
        unread: false
      },
      %{
        last_message: "The Redis cache implementation works great!",
        timestamp: "1d",
        unread: false
      },
      %{last_message: "Need help optimizing these DB queries", timestamp: "2d", unread: false},
      %{last_message: "Frontend tests are passing now 🎉", timestamp: "3d", unread: false},
      %{last_message: "How did you handle the WebRTC setup?", timestamp: "4d", unread: false},
      %{
        last_message: "The new CI pipeline reduced build times by 40%",
        timestamp: "5d",
        unread: false
      },
      %{
        last_message: "Let's pair program on the auth flow tomorrow?",
        timestamp: "1w",
        unread: false
      },
      %{
        last_message: "Just deployed the new search functionality",
        timestamp: "2w",
        unread: false
      },
      %{last_message: "The type system caught that bug early!", timestamp: "3w", unread: false},
      %{last_message: "Can you review these database indices?", timestamp: "1mo", unread: false},
      %{
        last_message: "The load balancer config is ready for review",
        timestamp: "2mo",
        unread: false
      },
      %{
        last_message: "Thanks for the help with that memory leak!",
        timestamp: "3mo",
        unread: false
      }
    ]

    # Zip the chat histories with matching devs
    chat_threads =
      matching_devs
      |> Enum.zip(chat_histories)
      |> Enum.map(fn {dev, history} ->
        %{
          id: dev.id,
          user: %{
            name: dev.name,
            avatar_url: dev.avatar_url
          },
          last_message: history.last_message,
          timestamp: history.timestamp,
          unread: history.unread
        }
      end)

    # Get a random user to chat with
    other_user = Enum.at(matching_devs, 8)

    other_user =
      Map.merge(other_user, %{
        timezone: "PST (UTC-8)",
        location: "Vancouver, Canada",
        availability: "Available for work",
        rate: "$120/hr",
        tech_stack: ["Elixir", "Phoenix", "React", "TypeScript", "PostgreSQL"],
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

    messages = [
      %{
        id: 1,
        sender: current_user,
        content:
          "yo! saw you've worked with Phoenix LiveView before. we're building a real-time collab tool and could use your expertise",
        sent_at: "11:30 AM",
        date: "Monday",
        is_self: true,
        avatar_url: current_user.avatar_url
      },
      %{
        id: 2,
        sender: other_user,
        content: "hey! yeah I've built a few things with LiveView. what kind of collab tool are you working on?",
        sent_at: "11:45 AM",
        date: "Monday",
        is_self: false,
        avatar_url: other_user.avatar_url
      },
      %{
        id: 3,
        sender: current_user,
        content:
          "it's like figma but for devs - shared coding environment with real-time cursors, chat, etc. biggest challenge right now is handling presence with 1000+ concurrent users",
        sent_at: "2:30 PM",
        date: "Yesterday",
        is_self: true,
        avatar_url: current_user.avatar_url
      },
      %{
        id: 4,
        sender: other_user,
        content:
          "oh nice! yeah Phoenix Presence would work well for that. I did something similar with LiveView for a collaborative whiteboard. had to do some tricks with debouncing to handle the cursor updates efficiently",
        sent_at: "3:15 PM",
        date: "Yesterday",
        is_self: false,
        avatar_url: other_user.avatar_url
      },
      %{
        id: 5,
        sender: current_user,
        content:
          "that's exactly what we need! mind taking a look at our presence.ex module? getting some weird race conditions when users disconnect",
        sent_at: "10:30 AM",
        date: "Today",
        is_self: true,
        avatar_url: current_user.avatar_url
      },
      %{
        id: 6,
        sender: other_user,
        content:
          "sure, drop a gist link. also check out :pg2 vs :pg - we had to switch because of similar issues at scale",
        sent_at: "10:32 AM",
        date: "Today",
        is_self: false,
        avatar_url: other_user.avatar_url
      },
      %{
        id: 7,
        sender: current_user,
        content: "awesome, here's the gist: https://gist.github.com/... also curious how you handled the pubsub sharding",
        sent_at: "10:35 AM",
        date: "Today",
        is_self: true,
        avatar_url: current_user.avatar_url
      }
    ]

    if connected?(socket) do
      {:ok,
       socket
       |> assign(
         messages: messages,
         current_user: current_user,
         other_user: other_user,
         chat_threads: chat_threads
       )
       |> push_event("scroll-to-bottom", %{})}
    else
      {:ok,
       assign(socket,
         messages: messages,
         current_user: current_user,
         other_user: other_user,
         chat_threads: chat_threads
       )}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-[calc(100vh-64px)] bg-background">
      <!-- Chat Threads Sidebar -->
      <div class="w-80 border-r border-border flex flex-col h-full">
        <div class="p-4 border-b border-border flex-none">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold">Messages</h2>
            <div class="flex gap-2">
              <.button variant="ghost" size="icon">
                <.icon name="tabler-filter" class="w-4 h-4" />
              </.button>
              <.button variant="ghost" size="icon">
                <.icon name="tabler-edit" class="w-4 h-4" />
              </.button>
            </div>
          </div>
          <div class="relative">
            <.icon
              name="tabler-search"
              class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground"
            />
            <.input
              type="search"
              name="search"
              placeholder="Search messages..."
              class="w-full pl-9"
              value=""
            />
          </div>
        </div>
        <.scroll_area class="flex-1">
          <div class="space-y-0.5">
            <%= for thread <- @chat_threads do %>
              <div class="flex items-center gap-3 p-3 hover:bg-muted/50 cursor-pointer transition-colors">
                <div class="relative">
                  <.avatar class="h-12 w-12">
                    <.avatar_image src={thread.user.avatar_url} />
                    <.avatar_fallback>{String.slice(thread.user.name, 0, 2)}</.avatar_fallback>
                  </.avatar>
                  <div class="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-success border-2 border-background">
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-center justify-between">
                    <span class="font-medium">{thread.user.name}</span>
                    <span class="text-xs text-muted-foreground">{thread.timestamp}</span>
                  </div>
                  <div class="flex items-center gap-2">
                    <p class="text-sm text-muted-foreground truncate">
                      {thread.last_message}
                    </p>
                    <%= if thread.unread do %>
                      <div class="w-2 h-2 rounded-full bg-primary flex-shrink-0"></div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </.scroll_area>
      </div>
      <!-- Main Chat Area -->
      <div class="flex-1 flex flex-col h-full">
        <div class="flex justify-between items-center border-b border-border p-4 flex-none bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div class="flex items-center gap-3">
            <div class="relative">
              <.avatar>
                <.avatar_image src={@other_user.avatar_url} alt="User avatar" />
                <.avatar_fallback>{String.slice(@other_user.name, 0, 2)}</.avatar_fallback>
              </.avatar>
              <div class="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-success border-2 border-background">
              </div>
            </div>
            <div>
              <h2 class="text-lg font-semibold">{@other_user.name}</h2>
              <p class="text-xs text-muted-foreground">Active now</p>
            </div>
          </div>
          <div class="flex gap-2">
            <.button variant="ghost" size="icon">
              <.icon name="tabler-phone" class="w-4 h-4" />
            </.button>
            <.button variant="ghost" size="icon">
              <.icon name="tabler-video" class="w-4 h-4" />
            </.button>
            <.button variant="ghost" size="icon">
              <.icon name="tabler-dots-vertical" class="w-4 h-4" />
            </.button>
          </div>
        </div>
        <.scroll_area
          class="flex-1 p-4 flex flex-col-reverse"
          id="messages-container"
          phx-hook="ScrollToBottom"
        >
          <div class="space-y-6">
            <%= for {date, messages} <- Enum.group_by(@messages, & &1.date) do %>
              <!-- Date separator -->
              <div class="flex items-center justify-center">
                <div class="text-xs text-muted-foreground bg-background px-2 py-1 rounded-full">
                  {date}
                </div>
              </div>

              <%= for message <- messages do %>
                <div class="flex gap-3 group">
                  <.avatar class="h-8 w-8">
                    <.avatar_image src={message.avatar_url} />
                    <.avatar_fallback>
                      {String.slice(message.sender.name, 0, 2)}
                    </.avatar_fallback>
                  </.avatar>
                  <div class="relative max-w-[80%] rounded-2xl p-3 bg-muted rounded-tl-none">
                    {message.content}
                    <div class="text-[10px] mt-1 text-muted-foreground">
                      {message.sent_at}
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </.scroll_area>
        <div class="border-t border-border p-4 flex-none bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
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
      <!-- Right Sidebar -->
      <div class="w-80 border-l border-border flex flex-col h-full">
        <div class="p-4">
          <div class="flex flex-col gap-6">
            <!-- User Profile Header -->
            <div class="flex flex-col items-center text-center">
              <.avatar class="h-20 w-20">
                <.avatar_image src={@other_user.avatar_url} />
                <.avatar_fallback>{String.slice(@other_user.name, 0, 2)}</.avatar_fallback>
              </.avatar>
              <h3 class="mt-4 text-lg font-semibold">
                {@other_user.name} {@other_user.flag}
              </h3>
              <p class="text-sm text-muted-foreground">@{@other_user.handle}</p>

              <div class="-mx-1 mt-3 flex flex-wrap gap-1 justify-center">
                <%= for tech <- Enum.take(@other_user.tech_stack || [], 3) do %>
                  <span class="rounded-lg px-2 py-0.5 text-xs ring-1 ring-border bg-secondary">
                    {tech}
                  </span>
                <% end %>
                <%= if length(@other_user.tech_stack || []) > 3 do %>
                  <span class="text-xs text-muted-foreground">
                    +{length(@other_user.tech_stack) - 3} more
                  </span>
                <% end %>
              </div>
            </div>
            <!-- User Details -->
            <div class="space-y-3">
              <div class="flex items-center gap-2 text-sm text-muted-foreground">
                <.icon name="tabler-map-pin" class="w-4 h-4" />
                {@other_user.location}
              </div>
              <div class="flex items-center gap-2 text-sm text-muted-foreground">
                <.icon name="tabler-clock" class="w-4 h-4" />
                {@other_user.timezone}
              </div>
              <div class="flex items-center gap-2 text-sm">
                <.icon name="tabler-circle-check" class="w-4 h-4 text-success" />
                <span class="text-success">{@other_user.availability}</span>
              </div>
              <div class="flex items-center gap-2 text-sm text-muted-foreground">
                <.icon name="tabler-currency-dollar" class="w-4 h-4" />
                {@other_user.rate}
              </div>
            </div>
            <!-- Social Links -->
            <div class="flex flex-col gap-3">
              <%= for social <- @other_user.socials do %>
                <a
                  href={social.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
                >
                  <.icon name={social.icon} class="w-4 h-4" />
                  {social.name}
                </a>
              <% end %>
            </div>
          </div>
        </div>

        <div class="p-4 mt-auto text-center">
          <.button variant="outline" href={"/devs/#{@other_user.handle}"} class="w-full">
            View Full Profile <.icon name="tabler-arrow-right" class="w-4 h-4 ml-2" />
          </.button>
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
      is_self: true,
      avatar_url: socket.assigns.current_user.avatar_url
    }

    {:noreply, update(socket, :messages, &(&1 ++ [new_message]))}
  end

  def handle_event("scroll-to-bottom", _, socket) do
    {:noreply, push_event(socket, "scroll-to-bottom", %{})}
  end
end
