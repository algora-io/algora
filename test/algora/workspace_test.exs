defmodule Algora.WorkspaceTest do
  use Algora.DataCase

  alias Algora.Workspace

  describe "list_user_contributions/2" do
    test "prioritizes highlighted contributions before higher-star default contributions" do
      user = insert!(:user)
      default_owner = insert!(:organization, provider_login: "default-owner", stargazers_count: 10_000)
      highlighted_owner = insert!(:organization, provider_login: "highlighted-owner", stargazers_count: 100)

      default_repo =
        insert!(:repository,
          user: default_owner,
          name: "large-star-project",
          stargazers_count: 10_000,
          tech_stack: ["Rust"]
        )

      highlighted_repo =
        insert!(:repository,
          user: highlighted_owner,
          name: "domain-project",
          stargazers_count: 100,
          tech_stack: ["Rust"]
        )

      insert!(:user_contribution, user: user, repository: default_repo, contribution_count: 1)

      insert!(:user_contribution,
        user: user,
        repository: highlighted_repo,
        contribution_count: 5,
        status: :highlighted
      )

      contributions = Workspace.list_user_contributions([user.id], display_all: true)

      assert Enum.map(contributions, & &1.repository.name) == ["domain-project", "large-star-project"]
    end

    test "hides hidden contributions unless requested" do
      user = insert!(:user)
      visible_owner = insert!(:organization, provider_login: "visible-owner")
      hidden_owner = insert!(:organization, provider_login: "hidden-owner")

      visible_repo =
        insert!(:repository,
          user: visible_owner,
          name: "visible-project",
          stargazers_count: 50,
          tech_stack: ["Elixir"]
        )

      hidden_repo =
        insert!(:repository,
          user: hidden_owner,
          name: "hidden-project",
          stargazers_count: 50_000,
          tech_stack: ["Elixir"]
        )

      insert!(:user_contribution, user: user, repository: visible_repo)
      insert!(:user_contribution, user: user, repository: hidden_repo, status: :hidden)

      visible_contributions = Workspace.list_user_contributions([user.id], display_all: true)
      all_contributions = Workspace.list_user_contributions([user.id], display_all: true, include_hidden: true)

      assert Enum.map(visible_contributions, & &1.repository.name) == ["visible-project"]
      assert Enum.map(all_contributions, & &1.repository.name) == ["hidden-project", "visible-project"]
    end
  end
end
