defmodule Algora.OnboardingTest do
  use Algora.DataCase

  @params %{
    member: %{role: :admin},
    user: %{
      handle: "test-pZW6",
      tech_stack: ["elixir", "pheonix"],
      email: "test@example.com",
      timezone: "America/New_York",
      display_name: "test",
      avatar_url: "https://www.gravatar.com/avatar/3db013cdb85ed7267579c0ccd5e930152722ffa7466b19105e6c70bed02402d5?d=&s=460&d=identicon",
      last_context: "test-tkPF"
    },
    organization: %{
      name: "test",
      handle: "test-tkPF",
      domain: "example.com",
      tech_stack: ["test"],
      email: "admin@example.com",
      hourly_rate_min: Money.new(:USD, "50"),
      hourly_rate_max: Money.new(:USD, "150"),
      hours_per_week: 40,
      display_name: "Test",
    },
    contract: %{
      start_date: DateTime.utc_now(),
      status: :draft,
      hourly_rate_min: Money.new(:USD, "50"),
      hourly_rate_max: Money.new(:USD, "150"),
      hours_per_week: 40
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
    end
  end
end
