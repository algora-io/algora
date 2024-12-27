defmodule AlgoraWeb.Components.Experts do
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

  # TODO: implement this
  def list_experts() do
    experts_file = :code.priv_dir(:algora) |> Path.join("dev/swift_experts.json")

    with true <- File.exists?(experts_file),
         {:ok, contents} <- File.read(experts_file),
         {:ok, experts} <- Jason.decode(contents) do
      experts
    else
      _ -> []
    end
  end
end
