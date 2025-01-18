defmodule AlgoraWeb.Activity.UserNavTimelineLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Activity

  def mount(_params, %{"user_id" => user_id} = session, socket) when is_binary(user_id) do
    {:ok,
     socket
     |> stream(:activities, [])
     |> start_async(:get_activities, fn -> Algora.Activities.all_for_user(user_id) end)}
  end

  def handle_async(:get_activities, {:ok, fetched}, socket) do
    {:noreply, stream(socket, :activities, fetched)}
  end

  def render(assigns) do
    ~H"""
    <.dropdown_activities activities={@streams.activities} id="activities-dropdown" />
    """
  end
end
