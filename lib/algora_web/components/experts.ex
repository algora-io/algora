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
  def list_experts(tech_stack) do
    experts_file = :code.priv_dir(:algora) |> Path.join("dev/experts/#{tech_stack}.json")

    with true <- File.exists?(experts_file),
         {:ok, contents} <- File.read(experts_file),
         {:ok, experts} <- Jason.decode(contents) do
      experts
    else
      _ -> []
    end
  end

  def list_techs do
    tech_order = [
      "Swift",
      "TypeScript",
      "Rust",
      "Scala",
      "C++",
      "Go",
      "Python",
      "Java",
      "PHP",
      "Elixir",
      "Haskell",
      "Ruby"
    ]

    Path.join(:code.priv_dir(:algora), "dev/experts")
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".json"))
    |> Enum.map(&String.trim_trailing(&1, ".json"))
    |> Enum.sort_by(fn tech -> Enum.find_index(tech_order, &(&1 == tech)) || 999 end)
  end
end
