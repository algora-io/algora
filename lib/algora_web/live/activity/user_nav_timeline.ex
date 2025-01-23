defmodule AlgoraWeb.Activity.UserNavTimelineLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Activity

  alias Algora.Activities

  def mount(_params, %{"user_id" => user_id}, socket) when is_binary(user_id) do
    :ok = Activities.subscribe_user(user_id)

    {:ok,
     socket
     |> stream(:activities, [])
     |> start_async(:get_activities, fn -> Activities.all_for_user(user_id) end)}
  end

  def handle_async(:get_activities, {:ok, fetched}, socket) do
    {:noreply, stream(socket, :activities, fetched)}
  end

  def handle_info(%Activities.Activity{} = activity, socket) do
    {:noreply, stream_insert(socket, :activities, activity, at: 0)}
  end

  def render(assigns) do
    ~H"""
    <.dropdown_activities activities={@streams.activities} id="activities-dropdown" />
    """
  end
end
