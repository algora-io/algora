defmodule Algora.OrganizationsTest do
  use Algora.DataCase

  @params %{
    member: %{role: :admin},
    user: %{
      handle: "zcesur-pZW6",
      display_name: "Zafer Cesur",
      tech_stack: ["Elixir", "Phoenix"],
      email: "zafer@algora.io"
    },
    organization: %{
      handle: "algora-tkPF",
      display_name: "Algora",
      tech_stack: ["Elixir", "Phoenix"],
      domain: "algora.io",
      categories: ["open_source", "agency"],
      hiring: true
    }
  }

  @params_crawler %{
    member: %{role: :admin},
    user: %{
      handle: "zafer-9XgZ",
      display_name: "Zafer Cesur",
      tech_stack: ["Elixir", "Phoenix"],
      email: "zafer@algora.io",
      avatar_url: "https://avatars.githubusercontent.com/u/17045339?v=4"
    },
    organization: %{
      handle: "algora-CEec",
      display_name: "Algora",
      tech_stack: ["Elixir", "Phoenix"],
      domain: "algora.io",
      categories: ["open_source", "agency"],
      hiring: true,
      youtube_url: "https://www.youtube.com/@algora-io",
      discord_url: "https://algora.io/discord",
      avatar_url: "https://console.algora.io/logo-512px.png",
      github_url: "https://github.com/algora-io",
      bio: "Algora is a developer tool & community simplifying bounties, hiring & open source sustainability.",
      website_url: "https://algora.io",
      twitter_url: "https://twitter.com/algoraio",
      twitch_url: "https://www.twitch.tv/algoratv",
      slack_url: "https://algora.io/discord",
      linkedin_url: "https://linkedin.com/company/algorapbc",
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
      assert org.hiring == true
    end

    test "onboard with crawler" do
      assert {:ok, %{user: user, org: org, member: _member}} =
               Algora.Organizations.onboard_organization(@params_crawler)

      assert org.display_name == "Algora"
      assert org.tech_stack == ["Elixir", "Phoenix"]
      assert org.categories == ["open_source", "agency"]
      assert org.hiring == true
      assert org.avatar_url == "https://console.algora.io/logo-512px.png"
      assert org.youtube_url == "https://www.youtube.com/@algora-io"
      assert org.discord_url == "https://algora.io/discord"
      assert org.avatar_url == "https://console.algora.io/logo-512px.png"
      assert org.github_url == "https://github.com/algora-io"
      assert org.bio =~ "Algora is"
      assert org.website_url == "https://algora.io"
      assert org.twitter_url == "https://twitter.com/algoraio"
      assert org.twitch_url == "https://www.twitch.tv/algoratv"
      assert org.slack_url == "https://algora.io/discord"
      assert org.linkedin_url == "https://linkedin.com/company/algorapbc"
      assert org.og_title == "Algora: Open source bounties"
      assert org.og_image_url == "https://console.algora.io/og.png"
      assert user.avatar_url == "https://avatars.githubusercontent.com/u/17045339?v=4"
    end

    test "onboard updates existing records when params change" do
      assert {:ok, first_result} = Algora.Organizations.onboard_organization(@params)

      updated_params =
        @params
        |> put_in([:user, :display_name], "Updated User")
        |> put_in([:user, :tech_stack], ["Haskell"])
        |> put_in([:organization, :display_name], "Updated Org")
        |> put_in([:organization, :tech_stack], ["Rust"])
        |> put_in([:organization, :categories], ["nonprofit"])
        |> put_in([:organization, :hiring], false)
        |> put_in([:member, :role], :mod)

      assert {:ok, second_result} = Algora.Organizations.onboard_organization(updated_params)

      assert first_result.user.id == second_result.user.id
      assert first_result.org.id == second_result.org.id
      assert first_result.member.id == second_result.member.id

      assert second_result.user.display_name == "Updated User"
      assert second_result.user.tech_stack == ["Haskell"]
      assert second_result.org.display_name == "Updated Org"
      assert second_result.org.tech_stack == ["Rust"]
      assert second_result.org.categories == ["nonprofit"]
      assert second_result.org.hiring == false
      assert second_result.member.role == :mod
    end
  end
end
