defmodule AlgoraWeb.Chat.ThreadLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Chat
  alias Algora.Chat.Message
  alias Algora.Repo

  @impl true
  def mount(%{"id" => thread_id}, _session, socket) do
    if connected?(socket) do
      Chat.subscribe(thread_id)
    end

    thread = thread_id |> Chat.get_thread() |> Repo.preload(participants: :user)
    messages = thread_id |> Chat.list_messages() |> Repo.preload(:sender)

    {:ok,
     socket
     |> assign(:thread, thread)
     |> assign(:thread_id, thread_id)
     |> assign(:messages, messages)}
  end

  @impl true
  def handle_event("send_message", %{"message" => content}, socket) do
    {:ok, message} =
      Chat.send_message(
        socket.assigns.thread_id,
        socket.assigns.current_user.id,
        content
      )

    {:noreply,
     socket
     |> Phoenix.Component.update(:messages, &(&1 ++ [message]))
     |> push_event("clear-input", %{selector: "#message-input"})}
  end

  @impl true
  def handle_info(%Message{} = message, socket) do
    if message.id in Enum.map(socket.assigns.messages, & &1.id) do
      {:noreply, socket}
    else
      {:noreply, Phoenix.Component.update(socket, :messages, &(&1 ++ [message]))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pr-80">
      <div class="flex flex-col h-[calc(100vh-4rem)]">
        <div class="flex-none border-b border-border bg-card/50 p-4 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="flex -space-x-2">
                <%= for participant <- @thread.participants do %>
                  <.avatar class="relative z-10 h-8 w-8 ring-2 ring-background">
                    <.avatar_image src={participant.user.avatar_url} alt={participant.user.name} />
                    <.avatar_fallback>
                      {Algora.Util.initials(participant.user.name)}
                    </.avatar_fallback>
                  </.avatar>
                <% end %>
              </div>
              <div>
                <h2 class="text-lg font-semibold">{@thread.title}</h2>
                <p class="text-xs text-muted-foreground">
                  {@thread.participants
                  |> Enum.map(& &1.user.name)
                  |> Algora.Util.format_name_list()}
                </p>
              </div>
            </div>
          </div>
        </div>

        <.scroll_area
          class="flex flex-1 flex-col-reverse gap-6 p-4"
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
                <div class="rounded-full bg-background px-2 py-1 text-xs text-muted-foreground">
                  {date}
                </div>
              </div>

              <div class="flex flex-col gap-6">
                <%= for message <- Enum.sort_by(messages, & &1.inserted_at, Date) do %>
                  <div class="group flex gap-3">
                    <.avatar class="h-8 w-8">
                      <.avatar_image src={message.sender.avatar_url} />
                      <.avatar_fallback>
                        {Algora.Util.initials(message.sender.name)}
                      </.avatar_fallback>
                    </.avatar>
                    <div class="max-w-[80%] relative rounded-2xl rounded-tl-none bg-muted p-3">
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

        <div class="flex-none bg-card/50 p-4 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <form phx-submit="send_message" class="flex items-center gap-2">
            <div class="relative flex-1">
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
              <div class="absolute top-1/2 right-2 flex -translate-y-1/2 gap-1">
                <.button
                  type="button"
                  variant="ghost"
                  size="icon-sm"
                  phx-hook="EmojiPicker"
                  id="emoji-trigger"
                >
                  <.icon name="tabler-mood-smile" class="h-4 w-4" />
                </.button>
              </div>
            </div>
            <.button type="submit" size="icon">
              <.icon name="tabler-send" class="h-4 w-4" />
            </.button>
          </form>
          <div id="emoji-picker-container" class="bottom-[80px] absolute right-4 hidden">
            <emoji-picker></emoji-picker>
          </div>
        </div>
      </div>

      <aside class="fixed top-[4rem] right-0 z-20 h-full w-72 border-l border-border bg-card/50 p-6 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div class="space-y-6">
          <div>
            <h3 class="mb-4 text-sm font-medium">Participants</h3>
            <div class="space-y-4">
              <%= for participant <- @thread.participants do %>
                <div class="flex items-center gap-3">
                  <.avatar class="h-10 w-10">
                    <.avatar_image src={participant.user.avatar_url} alt={participant.user.name} />
                    <.avatar_fallback>
                      {Algora.Util.initials(participant.user.name)}
                    </.avatar_fallback>
                  </.avatar>
                  <div>
                    <p class="text-sm font-medium leading-none">{participant.user.name}</p>
                    <p :if={participant.user.last_active_at} class="text-xs text-muted-foreground">
                      Active {Algora.Util.time_ago(participant.user.last_active_at)}
                    </p>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </aside>
    </div>
    """
  end
end
