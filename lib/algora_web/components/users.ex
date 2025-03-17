defmodule AlgoraWeb.Components.Users do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.Components.UserCard

  attr :users, :list, required: true

  def users(assigns) do
    ~H"""
    <%= for user <- @users do %>
      <li>
        <.user_card
          github_handle={user["github_handle"]}
          name={user["name"]}
          avatar_url={user["avatar_url"]}
          location={user["location"]}
          company={user["company"]}
          bio={user["bio"]}
          twitter_handle={user["twitter_handle"]}
        />
      </li>
    <% end %>
    """
  end
end
