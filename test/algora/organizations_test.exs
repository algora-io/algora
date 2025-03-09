defmodule Algora.OrganizationsTest do
  use Algora.DataCase

  @params %{
    member: %{role: :admin},
    user: %{
      display_name: "Algora",
      handle: "algora-pZW6",
      tech_stack: ["Elixir", "Phoenix"],
      email: "test@example.com",
      timezone: "America/New_York"
    },
    organization: %{
      display_name: "Algora",
      handle: "algora-tkPF",
      domain: "algora.io",
      tech_stack: ["Elixir", "Phoenix"],
      email: "admin@example.com",
      categories: ["open_source", "agency"]
    }
  }

  @params_crawler %{
    member: %{role: :admin},
    user: %{
      handle: "dev-9XgZ",
      avatar_url:
        "https://www.gravatar.com/avatar/69344de5f380397e2e2363f9a6a71e624b4d9ceecb53b78fab3463e8a1f702a6?d=&s=460&d=identicon",
      email: "dev@algora.io",
      display_name: "dev",
      last_context: "algora-CEec",
      timezone: "America/New_York",
      tech_stack: ["Elixir", "Phoenix"]
    },
    organization: %{
      handle: "algora-CEec",
      domain: "algora.io",
      youtube_url: nil,
      discord_url: nil,
      avatar_url: "https://console.algora.io/logo-512px.png",
      github_url: nil,
      email: "admin@algora.io",
      display_name: "Algora",
      bio: "Algora is a developer tool & community simplifying bounties, hiring & open source sustainability.",
      tech_stack: ["Elixir", "Phoenix"],
      website_url: nil,
      twitter_url: "https://twitter.com/algoraio",
      twitch_url: nil,
      slack_url: nil,
      linkedin_url: nil,
      og_title: "Algora: Open source bounties",
      og_image_url: "https://console.algora.io/og.png"
    }
  }

  describe "organizations" do
    test "onboard" do
      assert {:ok, %{user: user, org: org, member: member}} =
               Algora.Organizations.onboard_organization(@params)

      assert member.org_id == org.id
      assert member.user_id == user.id
      assert org.display_name == "Algora"
      assert org.tech_stack == ["Elixir", "Phoenix"]
      assert org.categories == ["open_source", "agency"]
    end

    test "onboard with crawler" do
      assert {:ok, %{user: user, org: org, member: _member}} =
               Algora.Organizations.onboard_organization(@params_crawler)

      assert org.avatar_url == "https://console.algora.io/logo-512px.png"
      assert user.avatar_url != org.avatar_url
    end
  end
end
