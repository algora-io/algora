defmodule Algora.WorkspaceTest do
  use Algora.DataCase

  alias Algora.Workspace

  defmodule GithubClientStub do
    def list_repository_languages(_token, "piedpiper", "middle-out"), do: {:ok, %{"Go" => 100, "Python" => 50}}
    def list_repository_languages(_token, _owner, _repo), do: {:ok, %{}}
  end

  describe "ensure_repo_tech_stack/3" do
    setup do
      previous_client = Application.get_env(:algora, :github_client)
      Application.put_env(:algora, :github_client, GithubClientStub)

      on_exit(fn ->
        Application.put_env(:algora, :github_client, previous_client)
      end)

      user = insert(:user, provider: "github", provider_login: "piedpiper", provider_id: "1")
      repository = insert(:repository, user: user, tech_stack: ["Java"], name: "middle-out")

      %{repository: Repo.preload(repository, :user)}
    end

    test "returns cached tech stack by default", %{repository: repository} do
      assert {:ok, ["Java"]} = Workspace.ensure_repo_tech_stack("token", repository)
      assert Repo.get!(Algora.Workspace.Repository, repository.id).tech_stack == ["Java"]
    end

    test "refreshes persisted tech stack when forced", %{repository: repository} do
      assert {:ok, ["Go", "Python"]} = Workspace.ensure_repo_tech_stack("token", repository, force: true)
      assert Repo.get!(Algora.Workspace.Repository, repository.id).tech_stack == ["Go", "Python"]
    end
  end
end
