defmodule AlgoraWeb.Constants do
  @moduledoc false
  use AlgoraWeb, :verified_routes

  def constants do
    %{
      email: "info@algora.io",
      twitter_url: "https://x.com/algoraio",
      youtube_url: "https://www.youtube.com/@algora-io",
      discord_url: ~p"/discord",
      github_url: "https://github.com/algora-io",
      # TODO: update this to the new repo
      github_repo_url: "https://github.com/algora-io/tv",
      docs_url: "https://docs.algora.io",
      docs_supported_countries_url: "https://docs.algora.io/bounties/payments#supported-countries-regions",
      demo_url: "https://www.youtube.com/watch?v=Ts5GhlEROrs",
      sdk_url: ~p"/sdk",
      privacy_url: ~p"/legal/privacy",
      terms_url: ~p"/legal/terms",
      blog_url: "https://blog.algora.io",
      contact_url: "https://docs.algora.io/contact",
      algora_tv_url: "https://algora.tv"
    }
  end

  def get(key), do: Map.get(constants(), key)
end
