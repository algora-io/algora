defmodule AlgoraWeb.BountiesLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Bounties

  alias Algora.Bounties

  require Logger

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bounties.subscribe()
    end

    {:ok, assign_tickets(socket)}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6">
      <.section title="Bounties" subtitle="Open bounties for you">
        <%= if Enum.empty?(@tickets) do %>
          <.card class="rounded-lg bg-card py-12 text-center lg:rounded-[2rem]">
            <.card_header>
              <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                <.icon name="tabler-diamond" class="h-8 w-8 text-muted-foreground" />
              </div>
              <.card_title>No bounties yet</.card_title>
              <.card_description>
                Open bounties will appear here once created
              </.card_description>
            </.card_header>
          </.card>
        <% else %>
          <.bounties tickets={@tickets} />
        <% end %>
      </.section>
    </div>
    """
  end

  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_tickets(socket)}
  end

  defp assign_tickets(socket) do
    tickets =
      Bounties.PrizePool.list(
        status: :open,
        tech_stack: socket.assigns.current_user.tech_stack,
        limit: 100
      )

    assign(socket, :tickets, tickets)
  end
end
