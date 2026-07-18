defmodule AlgoraWeb.User.ProfileLiveTest do
  use AlgoraWeb.ConnCase, async: true

  import Algora.Factory
  import Phoenix.LiveViewTest

  alias Algora.Repo
  alias Algora.Workspace.UserContribution

  test "lists top contributions per repository instead of collapsing them by owner", %{conn: conn} do
    user = insert!(:user, handle: "dev-user", provider_login: "dev-user")
    org = insert!(:organization, provider_login: "acme-org", stargazers_count: 50)

    repo_one = insert!(:repository, user: org, name: "repo-one", tech_stack: ["Elixir"], stargazers_count: 10)
    repo_two = insert!(:repository, user: org, name: "repo-two", tech_stack: ["Rust"], stargazers_count: 20)

    Repo.insert!(
      UserContribution.changeset(%UserContribution{}, %{
        user_id: user.id,
        repository_id: repo_one.id,
        contribution_count: 3,
        last_fetched_at: DateTime.utc_now(),
        status: :initial
      })
    )

    Repo.insert!(
      UserContribution.changeset(%UserContribution{}, %{
        user_id: user.id,
        repository_id: repo_two.id,
        contribution_count: 5,
        last_fetched_at: DateTime.utc_now(),
        status: :initial
      })
    )

    {:ok, _view, html} = live(conn, "/#{user.handle}")

    assert html =~ "repo-one"
    assert html =~ "repo-two"
    assert html =~ "https://github.com/acme-org/repo-one/pulls?q=author%3Adev-user+is%3Amerged+"
    assert html =~ "https://github.com/acme-org/repo-two/pulls?q=author%3Adev-user+is%3Amerged+"
  end
end
