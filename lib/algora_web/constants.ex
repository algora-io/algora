defmodule AlgoraWeb.Constants do
  @moduledoc false
  use AlgoraWeb, :verified_routes

  def constants do
    %{
      email: "info@algora.io",
      # TODO: use support@algora.io
      support_email: "info@algora.io",
      twitter_url: "https://x.com/algoraio",
      twitter_handle: "algoraio",
      youtube_url: "https://www.youtube.com/@algora-io",
      discord_url: ~p"/discord",
      github_url: "https://github.com/algora-io",
      linkedin_url: "https://linkedin.com/company/algorapbc",
      calendar_url: "https://cal.com/ioannisflo",
      github_repo_url: "https://github.com/algora-io/algora",
      github_repo_api_url: "https://api.github.com/repos/algora-io/algora",
      docs_url: ~p"/docs",
      docs_supported_countries_url: ~p"/docs/payments",
      demo_url: "https://www.youtube.com/watch?v=Ts5GhlEROrs",
      sdk_url: ~p"/sdk",
      privacy_url: ~p"/legal/privacy",
      terms_url: ~p"/legal/terms",
      blog_url: "https://blog.algora.io",
      contact_url: ~p"/docs/contact",
      algora_tv_url: "https://algora.tv",
      tel_formatted: "+1 (650) 420-2207",
      tel: "+16504202207"
    }
  end

  def get(key), do: Map.get(constants(), key)
end
