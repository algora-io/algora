defmodule AlgoraWeb.BountyLive.Index do
  use AlgoraWeb, :live_view

  alias Algora.Bounties

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :bounties, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Bounties")
    |> assign(:bounty, nil)
    |> assign_filters(params)
    |> stream(:bounties, list_bounties(params), reset: true)
  end

  defp assign_filters(socket, params) do
    socket
    |> assign(:status_filter, params["status"])
    |> assign(:search_query, params["search"])
    |> assign(:min_amount, params["min_amount"])
    |> assign(:max_amount, params["max_amount"])
  end

  defp list_bounties(params) do
    filters = %{
      status: params["status"],
      search: params["search"],
      min_amount: parse_amount(params["min_amount"]),
      max_amount: parse_amount(params["max_amount"])
    }
    
    Bounties.list_bounties(filters)
  end

  defp parse_amount(nil), do: nil
  defp parse_amount(""), do: nil
  defp parse_amount(amount) when is_binary(amount) do
    case Integer.parse(amount) do
      {parsed, ""} -> parsed
      _ -> nil
    end
  end
  defp parse_amount(amount) when is_integer(amount), do: amount

  @impl true
  def handle_event("filter", %{"status" => status, "search" => search, "min_amount" => min_amount, "max_amount" => max_amount}, socket) do
    params = %{
      "status" => if(status == "", do: nil, else: status),
      "search" => if(search == "", do: nil, else: search),
      "min_amount" => if(min_amount == "", do: nil, else: min_amount),
      "max_amount" => if(max_amount == "", do: nil, else: max_amount)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()

    {:noreply, push_patch(socket, to: ~p"/bounties?#{params}")}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/bounties")}
  end
end