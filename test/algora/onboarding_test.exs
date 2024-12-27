defmodule Algora.OnboardingTest do
  use Algora.DataCase

  @params %{
    member: %{role: :admin},
    user: %{
      display_name: "Algora",
      handle: "algora-pZW6",
      tech_stack: ["Elixir", "Pheonix"],
      email: "test@example.com",
      timezone: "America/New_York",
    },
    organization: %{
      display_name: "Algora",
      handle: "algora-tkPF",
      domain: "algora.io",
      tech_stack: ["test"],
      email: "admin@example.com",
      hourly_rate_min: Money.new(:USD, "50"),
      hourly_rate_max: Money.new(:USD, "150"),
      hours_per_week: 40,
    },
    contract: %{
      start_date: DateTime.utc_now(),
      status: :draft,
      hourly_rate_min: Money.new(:USD, "50"),
      hourly_rate_max: Money.new(:USD, "150"),
      hours_per_week: 40
    }
  }

  @params_crawler %{
    member: %{role: :admin},
    user: %{
      handle: "dev-9XgZ",
      avatar_url: "https://www.gravatar.com/avatar/69344de5f380397e2e2363f9a6a71e624b4d9ceecb53b78fab3463e8a1f702a6?d=&s=460&d=identicon",
      email: "dev@algora.io",
      display_name: "dev",
      last_context: "algora-CEec",
      timezone: "America/New_York",
      tech_stack: ["Elixir", "Pheonix"]
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
      tech_stack: ["Elixir", "Pheonix"],
      hourly_rate_min: Money.new(:USD, "50"),
      hourly_rate_max: Money.new(:USD, "150"),
      hours_per_week: 40,
      website_url: nil,
      twitter_url: "https://twitter.com/algoraio",
      twitch_url: nil,
      slack_url: nil,
      linkedin_url: nil,
      og_title: "Algora: Open source bounties",
      og_image_url: "https://console.algora.io/og.png"
    },
    contract: %{
      status: :draft,
      hourly_rate_min: Money.new(:USD, "50"),
      hourly_rate_max: Money.new(:USD, "150"),
      hours_per_week: 40,
      start_date: ~U[2024-12-27 01:30:51.117317Z]
    }
  }

  describe "onboarding" do
    test "create" do
      assert {:ok, %{user: user, org: org, member: member, contract: contract}} =
        Algora.Organizations.onboard_organization(@params)

      assert member.org_id == org.id
      assert member.user_id == user.id
      assert contract.client_id == org.id
      assert contract.status == :draft
      assert contract.hourly_rate_min == Money.new(:USD, "50")
      assert contract.hourly_rate_max == Money.new(:USD, "150")
      assert org.hourly_rate_min == Money.new(:USD, "50")
      assert org.hourly_rate_max == Money.new(:USD, "150")
      assert org.display_name == "Algora"
    end

    test "create with crawler" do
      assert {:ok, %{user: user, org: org, member: member, contract: contract}} =
        Algora.Organizations.onboard_organization(@params_crawler)

      assert org.avatar_url == "https://console.algora.io/logo-512px.png"
      assert user.avatar_url != org.avatar_url
    end
  end
end
