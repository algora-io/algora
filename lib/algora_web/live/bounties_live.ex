defmodule AlgoraWeb.BountiesLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Bounties

  alias Algora.Accounts
  alias Algora.Bounties

  require Logger

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bounties.subscribe()
    end

    query_opts =
      [
        status: :open,
        limit: page_size()
      ] ++
        if socket.assigns.current_user do
          [amount_gt: Money.new(:USD, 200)]
        else
          [amount_gt: Money.new(:USD, 500)]
        end

    techs = Bounties.list_tech(query_opts)
    selected_techs = []

    query_opts = if selected_techs == [], do: query_opts, else: Keyword.put(query_opts, :tech_stack, selected_techs)

    {:ok,
     socket
     |> assign(:techs, techs)
     |> assign(:selected_techs, selected_techs)
     |> assign(:query_opts, query_opts)
     |> assign_bounties()}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6 lg:px-8">
      <.section title="Bounties" subtitle="Open bounties for you">
        <div class="-mt-4 mb-4 flex flex-wrap gap-2">
          <%= for {tech, count} <- @techs do %>
            <div phx-click="toggle_tech" phx-value-tech={tech} class="cursor-pointer">
              <.badge
                variant={if tech in @selected_techs, do: "success", else: "outline"}
                class="hover:bg-white/[4%] transition-colors"
              >
                {tech} ({count})
              </.badge>
            </div>
          <% end %>
        </div>
        <%= if Enum.empty?(@bounties) do %>
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
          <div id="bounties-container" phx-hook="InfiniteScroll">
            <.bounties bounties={@bounties} />
            <div :if={@has_more_bounties} class="flex justify-center mt-4" id="load-more-indicator">
              <div class="animate-pulse text-muted-foreground">
                <.icon name="tabler-loader" class="h-6 w-6 animate-spin" />
              </div>
            </div>
          </div>
        <% end %>
      </.section>
    </div>
    """
  end

  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_bounties(socket)}
  end

  def handle_event("load_more", _params, socket) do
    %{bounties: bounties} = socket.assigns

    more_bounties =
      Bounties.list_bounties(
        Keyword.put(socket.assigns.query_opts, :before, %{
          inserted_at: List.last(bounties).inserted_at,
          id: List.last(bounties).id
        })
      )

    {:noreply,
     socket
     |> assign(:bounties, bounties ++ more_bounties)
     |> assign(:has_more_bounties, length(more_bounties) >= page_size())}
  end

  def handle_event("toggle_tech", %{"tech" => tech}, socket) do
    selected_techs =
      if tech in socket.assigns.selected_techs do
        List.delete(socket.assigns.selected_techs, tech)
      else
        [tech | socket.assigns.selected_techs]
      end

    query_opts =
      if selected_techs == [] do
        Keyword.delete(socket.assigns.query_opts, :tech_stack)
      else
        Keyword.put(socket.assigns.query_opts, :tech_stack, selected_techs)
      end

    {:noreply,
     socket
     |> assign(:selected_techs, selected_techs)
     |> assign(:query_opts, query_opts)
     |> assign_bounties()}
  end

  defp assign_bounties(socket) do
    bounties = Bounties.list_bounties(socket.assigns.query_opts)

    socket
    |> assign(:bounties, bounties)
    |> assign(:has_more_bounties, length(bounties) >= page_size())
  end

  defp page_size, do: 10
end
