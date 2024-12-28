defmodule AlgoraWeb.BountiesLive do
  use AlgoraWeb, :live_view
  require Logger
  import AlgoraWeb.Components.Bounties
  alias Algora.Bounties

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bounties.subscribe()
    end

    {:ok, socket |> assign_tickets()}
  end

  def render(assigns) do
    ~H"""
    <div class="container max-w-7xl mx-auto p-6 space-y-6">
      <.section title="Bounties" subtitle="Open bounties for you">
        <.bounties tickets={@tickets} />
      </.section>
    </div>
    """
  end

  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_tickets(socket)}
  end

  defp assign_tickets(socket) do
    tickets =
      Bounties.TicketView.list(
        status: :open,
        tech_stack: socket.assigns.current_user.tech_stack,
        limit: 100
      ) ++
        Bounties.TicketView.sample_tickets()

    socket |> assign(:tickets, tickets |> Enum.take(6))
  end
end
