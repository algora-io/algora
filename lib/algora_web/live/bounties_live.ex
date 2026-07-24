defmodule AlgoraWeb.BountiesLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Bounties

  alias Algora.Bounties
  alias Algora.Jobs
  alias Algora.Payments

  require Logger

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign_filters(socket, params)}
  end

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket) do
      Bounties.subscribe()
    end

    default_min_amount = default_min_amount(socket)

    {:ok,
     socket
     |> assign(:base_query_opts, [
       status: :open,
       limit: page_size(),
       current_user: socket.assigns[:current_user]
     ])
     |> assign(:default_min_amount, default_min_amount)
     |> assign_filters(params)
     |> assign_events()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-4 md:p-6 lg:px-8">
      <.section title="Bounties" subtitle="Open bounties for you">
        <form
          phx-change="filter_amount"
          phx-submit="filter_amount"
          class="mb-4 flex flex-wrap items-end gap-2"
        >
          <div class="w-32">
            <.input
              type="number"
              id="bounty-min-amount"
              name="min"
              label="Min"
              min="0"
              value={@min_amount || ""}
              phx-debounce="300"
            />
          </div>
          <span class="pb-2 text-sm text-muted-foreground">-</span>
          <div class="w-32">
            <.input
              type="number"
              id="bounty-max-amount"
              name="max"
              label="Max"
              min="0"
              value={@max_amount || ""}
              phx-debounce="300"
            />
          </div>
          <.button type="submit">Apply</.button>
        </form>
        <div class="mb-4 flex sm:flex-wrap gap-2 whitespace-nowrap overflow-x-auto scrollbar-thin">
          <%= for {tech, count} <- @techs do %>
            <div phx-click="toggle_tech" phx-value-tech={tech} class="cursor-pointer">
              <.badge
                variant={if String.downcase(tech) in @selected_techs, do: "success", else: "default"}
                class={
                  if String.downcase(tech) in @selected_techs,
                    do: "hover:bg-success/5 transition-colors",
                    else: "hover:bg-accent/80 transition-colors"
                }
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
            <div :if={@has_more_bounties} class="flex justify-center mt-4" data-load-more-indicator>
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
      build_query_opts(
        socket.assigns.base_query_opts,
        selected_techs,
        socket.assigns.min_amount,
        socket.assigns.max_amount
      )

    path =
      bounties_path(
        selected_techs,
        socket.assigns.min_amount,
        socket.assigns.max_amount,
        socket.assigns.default_min_amount
      )

    {:noreply,
     socket
     |> push_patch(to: path)
     |> assign(:selected_techs, selected_techs)
     |> assign(:query_opts, query_opts)
     |> assign_bounties()}
  end

  @impl true
  def handle_event("filter_amount", params, socket) do
    {min_amount, max_amount} = parse_amount_params(params, socket.assigns.default_min_amount)

    query_opts =
      build_query_opts(
        socket.assigns.base_query_opts,
        socket.assigns.selected_techs,
        min_amount,
        max_amount
      )

    path =
      bounties_path(
        socket.assigns.selected_techs,
        min_amount,
        max_amount,
        socket.assigns.default_min_amount
      )

    {:noreply,
     socket
     |> push_patch(to: path)
     |> assign(:min_amount, min_amount)
     |> assign(:max_amount, max_amount)
     |> assign(:query_opts, query_opts)
     |> assign_bounties()}
  end

  defp assign_filters(socket, params) do
    {min_amount, max_amount} = parse_amount_params(params, socket.assigns.default_min_amount)
    tech_query_opts = build_query_opts(socket.assigns.base_query_opts, [], min_amount, max_amount)
    techs = Bounties.list_tech(tech_query_opts)
    selected_techs = parse_selected_techs(params["tech"], techs)

    query_opts =
      build_query_opts(socket.assigns.base_query_opts, selected_techs, min_amount, max_amount)

    socket
    |> assign(:page_title, page_title(selected_techs))
    |> assign(:techs, techs)
    |> assign(:selected_techs, selected_techs)
    |> assign(:min_amount, min_amount)
    |> assign(:max_amount, max_amount)
    |> assign(:query_opts, query_opts)
    |> assign_bounties()
  end

  defp parse_selected_techs(tech, techs) when is_binary(tech) do
    valid_techs = Enum.map(techs, fn {tech, _} -> String.downcase(tech) end)

    tech
    |> String.split(",")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.downcase/1)
    |> Enum.filter(&(&1 in valid_techs))
  end

  defp parse_selected_techs(_tech, _techs), do: []

  defp parse_amount_params(params, default_min_amount) do
    min_amount = parse_amount(params["min"])
    max_amount = parse_amount(params["max"])

    min_amount =
      if blank?(params["min"]) and blank?(params["max"]) do
        default_min_amount
      else
        min_amount
      end

    {min_amount, max_amount}
  end

  defp parse_amount(amount) when is_binary(amount) do
    case Integer.parse(amount) do
      {amount, ""} when amount >= 0 -> amount
      _ -> nil
    end
  end

  defp parse_amount(_amount), do: nil

  defp blank?(value), do: value in [nil, ""]

  defp build_query_opts(base_query_opts, selected_techs, min_amount, max_amount) do
    base_query_opts
    |> maybe_put_amount_gt(min_amount)
    |> maybe_put_amount_lt(max_amount)
    |> maybe_put_tech_stack(selected_techs)
  end

  defp maybe_put_amount_gt(query_opts, nil), do: query_opts
  defp maybe_put_amount_gt(query_opts, amount) do
    Keyword.put(query_opts, :amount_gt, Money.new(:USD, amount))
  end

  defp maybe_put_amount_lt(query_opts, nil), do: query_opts
  defp maybe_put_amount_lt(query_opts, amount) do
    Keyword.put(query_opts, :amount_lt, Money.new(:USD, amount))
  end

  defp maybe_put_tech_stack(query_opts, []), do: query_opts
  defp maybe_put_tech_stack(query_opts, selected_techs) do
    Keyword.put(query_opts, :tech_stack, selected_techs)
  end

  defp bounties_path(selected_techs, min_amount, max_amount, default_min_amount) do
    path =
      if selected_techs == [] do
        ~p"/bounties"
      else
        ~p"/bounties/#{Enum.join(selected_techs, ",")}"
      end

    case amount_query_params(min_amount, max_amount, default_min_amount) do
      [] -> path
      params -> path <> "?" <> URI.encode_query(params)
    end
  end

  defp amount_query_params(min_amount, max_amount, default_min_amount) do
    []
    |> maybe_put_amount_query_param("max", max_amount, not is_nil(max_amount))
    |> maybe_put_amount_query_param(
      "min",
      min_amount,
      not is_nil(min_amount) and (min_amount != default_min_amount or not is_nil(max_amount))
    )
  end

  defp maybe_put_amount_query_param(params, key, amount, true), do: [{key, amount} | params]
  defp maybe_put_amount_query_param(params, _key, _amount, _put?), do: params

  defp page_title([]), do: "Bounties"
  defp page_title(selected_techs) do
    "#{Enum.map_join(selected_techs, "/", &String.capitalize/1)} Bounties"
  end

  defp default_min_amount(socket), do: if(socket.assigns[:current_user], do: 100, else: 500)

  defp assign_bounties(socket) do
    bounties = Bounties.list_bounties(socket.assigns.query_opts)

    socket
    |> assign(:bounties, bounties)
    |> assign(:has_more_bounties, length(bounties) >= page_size())
  end

  defp page_size, do: 10

  defp assign_events(socket) do
    transactions = Payments.list_featured_transactions()
    jobs_by_user = Enum.group_by(Jobs.list_jobs(), & &1.user)

    events =
      transactions
      |> Enum.map(fn tx -> %{item: tx, type: :transaction, timestamp: tx.succeeded_at} end)
      |> Enum.concat(
        jobs_by_user
        |> Enum.flat_map(fn {_user, jobs} -> jobs end)
        |> Enum.map(fn job -> %{item: job, type: :job, timestamp: job.inserted_at} end)
      )
      |> Enum.concat(
        Enum.map(socket.assigns.bounties || [], fn bounty ->
          %{item: bounty, type: :bounty, timestamp: bounty.inserted_at}
        end)
      )
      |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})

    assign(socket, :events, events)
  end
end
