defmodule AlgoraWeb.BountiesLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Bounties

  alias Algora.Bounties

  require Logger

  @impl true
  def handle_params(%{"tech" => tech}, _uri, socket) when is_binary(tech) do
    selected_techs = tech |> String.split(",") |> Enum.reject(&(&1 == "")) |> Enum.map(&String.downcase/1)
    valid_techs = Enum.map(socket.assigns.techs, fn {tech, _} -> String.downcase(tech) end)
    # Only keep valid techs that exist in the available tech list
    selected_techs = Enum.filter(selected_techs, &(&1 in valid_techs))

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

  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:selected_techs, [])
     |> assign(:query_opts, Keyword.delete(socket.assigns.query_opts, :tech_stack))
     |> assign_bounties()}
  end

  @impl true
  def mount(%{"tech" => tech}, _session, socket) when is_binary(tech) do
    if connected?(socket) do
      Bounties.subscribe()
    end

    # Parse selected techs from URL params and ensure lowercase
    selected_techs =
      tech
      |> String.split(",")
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.downcase/1)

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

    # Only keep valid techs that exist in the available tech list (case insensitive)
    valid_techs = Enum.map(techs, fn {tech, _} -> String.downcase(tech) end)
    selected_techs = Enum.filter(selected_techs, &(&1 in valid_techs))

    query_opts = if selected_techs == [], do: query_opts, else: Keyword.put(query_opts, :tech_stack, selected_techs)

    {:ok,
     socket
     |> assign(:techs, techs)
     |> assign(:selected_techs, selected_techs)
     |> assign(:query_opts, query_opts)
     |> assign_bounties()}
  end

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

    {:ok,
     socket
     |> assign(:techs, techs)
     |> assign(:selected_techs, [])
     |> assign(:query_opts, query_opts)
     |> assign_bounties()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-4 md:p-6 lg:px-8">
      <.section title="Bounties" subtitle="Open bounties for you">
        <div class="mb-4 flex sm:flex-wrap gap-2 whitespace-nowrap overflow-x-auto scrollbar-thin">
          <%= for {tech, count} <- @techs do %>
            <div phx-click="toggle_tech" phx-value-tech={tech} class="cursor-pointer">
              <.badge
                variant={if String.downcase(tech) in @selected_techs, do: "success", else: "outline"}
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

  @impl true
  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_bounties(socket)}
  end

  @impl true
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

  @impl true
  def handle_event("toggle_tech", %{"tech" => tech}, socket) do
    tech = String.downcase(tech)

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

    # Update the URL with selected techs
    path = if selected_techs == [], do: ~p"/bounties", else: ~p"/bounties/#{Enum.join(selected_techs, ",")}"

    {:noreply,
     socket
     |> push_patch(to: path)
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
