defmodule AlgoraWeb.Components.Experts do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.Components.ExpertCard

  attr :experts, :list, required: true

  def experts(assigns) do
    ~H"""
    <%= for expert <- @experts do %>
      <li>
        <.expert_card
          github_handle={expert["github_handle"]}
          name={expert["name"]}
          avatar_url={expert["avatar_url"]}
          location={expert["location"]}
          company={expert["company"]}
          bio={expert["bio"]}
          twitter_handle={expert["twitter_handle"]}
        />
      </li>
    <% end %>
    """
  end
end
