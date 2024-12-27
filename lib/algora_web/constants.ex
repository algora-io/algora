defmodule AlgoraWeb.Constants do
  def constants do
    %{
      email: "info@algora.io",
      twitter_url: "https://x.com/algoraio",
      youtube_url: "https://www.youtube.com/@algora-io",
      discord_url: "https://algora.io/discord",
      github_url: "https://github.com/algora-io",
      # TODO: update this to the new repo
      github_repo_url: "https://github.com/algora-io/tv",
      docs_url: "https://docs.algora.io",
      demo_url: "https://www.youtube.com/watch?v=Ts5GhlEROrs",
      sdk_url: "https://console.algora.io/sdk",
      privacy_url: "https://console.algora.io/legal/privacy",
      terms_url: "https://console.algora.io/legal/terms",
      blog_url: "https://blog.algora.io",
      contact_url: "https://docs.algora.io/contact"
    }
  end

  def get(key), do: Map.get(constants(), key)
end
