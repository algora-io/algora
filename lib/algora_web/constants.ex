defmodule AlgoraWeb.Constants do
  def constants do
    %{
      youtube_url: "https://www.youtube.com/@algora-io",
      discord_url: "https://algora.io/discord",
      # TODO: update this to the new repo
      github_url: "https://github.com/algora-io/tv",
      docs_url: "https://docs.algora.io"
    }
  end

  def get(key), do: Map.get(constants(), key)
end
