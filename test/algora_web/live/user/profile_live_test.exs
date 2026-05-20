defmodule AlgoraWeb.User.ProfileLiveTest do
  use AlgoraWeb.ConnCase, async: false

  import Algora.Factory
  import Phoenix.LiveViewTest

  alias Algora.Repo
  alias Algora.Workspace.UserContribution

  test "links organization contribution cards to owner-wide pull search", %{conn: conn} do
    user = insert(:user, handle: "contributor", provider_login: "contributor")
    org = insert(:organization, display_name: "Transloadit", provider_login: "transloadit")

    repo_a = insert(:repository, user_id: org.id, name: "uppy", tech_stack: ["TypeScript"], stargazers_count: 500)

    repo_b =
      insert(:repository, user_id: org.id, name: "tus-js-client", tech_stack: ["TypeScript"], stargazers_count: 250)

    insert_contribution!(user, repo_a, 2)
    insert_contribution!(user, repo_b, 3)

    {:ok, _view, html} = live(conn, ~p"/#{user.handle}/profile")
    assert html =~ "Transloadit"
    assert html =~ "github.com/pulls"
    assert html =~ "author%3Acontributor+is%3Amerged+org%3Atransloadit"
    refute html =~ "github.com/transloadit/uppy/pulls"
  end

  defp insert_contribution!(user, repository, contribution_count) do
    %UserContribution{}
    |> UserContribution.changeset(%{
      user_id: user.id,
      repository_id: repository.id,
      contribution_count: contribution_count,
      last_fetched_at: DateTime.utc_now()
    })
    |> Repo.insert!()
  end
end
