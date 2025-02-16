defmodule AlgoraWeb.Webhooks.GithubControllerTest do
  use AlgoraWeb.ConnCase

  import Algora.Factory
  import Money.Sigil
  import Mox

  alias Algora.Bounties.Claim
  alias Algora.Github.Webhook
  alias Algora.Repo
  alias AlgoraWeb.Webhooks.GithubController

  setup :verify_on_exit!

  @admin_user "jsmith"
  @unauthorized_user "jdoe"
  @repo_owner "owner"
  @repo_name "repo"
  @installation_id 123

  @webhook %Webhook{
    event: "issue_comment",
    hook_id: "123456789",
    delivery: "00000000-0000-0000-0000-000000000000",
    signature: "sha1=0000000000000000000000000000000000000000",
    signature_256: "sha256=0000000000000000000000000000000000000000000000000000000000000000",
    user_agent: "GitHub-Hookshot/0000000",
    installation_type: "integration",
    installation_id: "123456"
  }

  @params %{
    "id" => 123,
    "action" => "created",
    "repository" => %{
      "owner" => %{"login" => @repo_owner},
      "name" => @repo_name
    },
    "issue" => %{
      "number" => 123
    },
    "installation" => %{
      "id" => @installation_id
    }
  }

  setup do
    admin = insert!(:user, handle: @admin_user)
    org = insert!(:organization, handle: @repo_owner)

    installation =
      insert!(:installation, %{
        owner: admin,
        connected_user: org,
        provider_id: to_string(@installation_id)
      })

    %{admin: admin, org: org, installation: installation}
  end

  describe "bounty command" do
    setup [:setup_github_mocks]

    @tag user: @unauthorized_user
    test "handles bounty command with unauthorized user", %{user: user} do
      assert {:error, :unauthorized} = process_commands("issue_comment.created", "/bounty $100", user)
    end

    test "handles bounty command without amount" do
      assert {:ok, []} = process_commands("issue_comment.created", "/bounty")
    end

    test "handles valid bounty command with $ prefix" do
      assert {:ok, [bounty]} = process_commands("issue_comment.created", "/bounty $100")
      assert bounty.amount == ~M[100]usd
    end

    test "handles invalid bounty command with $ suffix" do
      assert {:ok, [bounty]} = process_commands("issue_comment.created", "/bounty 100$")
      assert bounty.amount == ~M[100]usd
    end

    test "handles bounty command without $ symbol" do
      assert {:ok, [bounty]} = process_commands("issue_comment.created", "/bounty 100")
      assert bounty.amount == ~M[100]usd
    end

    test "handles bounty command with decimal amount" do
      assert {:ok, [bounty]} = process_commands("issue_comment.created", "/bounty 100.50")
      assert bounty.amount == ~M[100.50]usd
    end

    test "handles bounty command with partial decimal amount" do
      assert {:ok, [bounty]} = process_commands("issue_comment.created", "/bounty 100.5")
      assert bounty.amount == ~M[100.5]usd
    end

    test "handles bounty command with decimal amount and $ prefix" do
      assert {:ok, [bounty]} = process_commands("issue_comment.created", "/bounty $100.50")
      assert bounty.amount == ~M[100.50]usd
    end

    test "handles bounty command with partial decimal amount and $ prefix" do
      assert {:ok, [bounty]} = process_commands("issue_comment.created", "/bounty $100.5")
      assert bounty.amount == ~M[100.5]usd
    end

    test "handles bounty command with decimal amount and $ suffix" do
      assert {:ok, [bounty]} = process_commands("issue_comment.created", "/bounty 100.50$")
      assert bounty.amount == ~M[100.50]usd
    end

    test "handles bounty command with partial decimal amount and $ suffix" do
      assert {:ok, [bounty]} = process_commands("issue_comment.created", "/bounty 100.5$")
      assert bounty.amount == ~M[100.5]usd
    end

    test "handles bounty command with comma separator" do
      assert {:ok, [bounty]} = process_commands("issue_comment.created", "/bounty 1,000")
      assert bounty.amount == ~M[1000]usd
    end

    test "handles bounty command with comma separator and decimal amount" do
      assert {:ok, [bounty]} = process_commands("issue_comment.created", "/bounty 1,000.50")
      assert bounty.amount == ~M[1000.50]usd
    end
  end

  describe "pull request closed event" do
    setup [:setup_github_mocks]

    test "handles unmerged pull request", context do
      {claim, params} = setup_claim(context)
      params = put_in(params, ["pull_request", "merged_at"], nil)

      assert :ok == GithubController.process_event("pull_request.closed", params)

      updated_claim = Repo.get(Claim, claim.id)
      assert updated_claim.status == :pending
    end

    test "handles merged pull request with claims", context do
      {claim, params} = setup_claim(context)
      params = put_in(params, ["pull_request", "merged_at"], DateTime.to_iso8601(DateTime.utc_now()))

      assert :ok == GithubController.process_event("pull_request.closed", params)

      updated_claim = Repo.get(Claim, claim.id)
      assert updated_claim.status == :approved
    end

    test "handles merged pull request without claims", context do
      {claim, params} = setup_claim(context)

      params =
        params
        |> put_in(["pull_request", "merged_at"], DateTime.to_iso8601(DateTime.utc_now()))
        |> put_in(["pull_request", "number"], claim.source.number + 1)

      assert :ok == GithubController.process_event("pull_request.closed", params)

      updated_claim = Repo.get(Claim, claim.id)
      assert updated_claim.status == :pending
    end
  end

  defp setup_claim(context) do
    author = insert!(:user)
    repository = insert!(:repository, user: context[:org])
    target = insert!(:ticket, repository: repository)
    source = insert!(:ticket, repository: repository)
    claim = insert!(:claim, user: author, target: target, source: source, status: :pending)

    params = %{
      "action" => "closed",
      "repository" => %{
        "id" => String.to_integer(repository.provider_id),
        "owner" => %{"login" => context[:org].provider_login},
        "name" => repository.name
      },
      "pull_request" => %{
        "merged_at" => DateTime.to_iso8601(DateTime.utc_now()),
        "number" => source.number,
        "user" => %{"id" => String.to_integer(author.provider_id)}
      },
      "installation" => %{
        "id" => String.to_integer(context[:installation].provider_id)
      }
    }

    {claim, params}
  end

  defp setup_github_mocks(context) do
    setup_installation_token()
    setup_repository_permissions(context[:user] || @admin_user)
    setup_create_issue_comment()
    setup_get_user_by_username()
    setup_get_issue()
    setup_get_repository()
    :ok
  end

  defp setup_installation_token do
    stub(
      Algora.GithubMock,
      :get_installation_token,
      fn _installation_id -> {:ok, %{"token" => "test_token"}} end
    )
  end

  defp setup_repository_permissions(@admin_user) do
    stub(
      Algora.GithubMock,
      :get_repository_permissions,
      fn _token, _owner, _repo, _user -> {:ok, %{"permission" => "admin"}} end
    )
  end

  defp setup_repository_permissions(@unauthorized_user) do
    stub(
      Algora.GithubMock,
      :get_repository_permissions,
      fn _token, _owner, _repo, _user -> {:ok, %{"permission" => "none"}} end
    )
  end

  defp setup_create_issue_comment do
    stub(
      Algora.GithubMock,
      :create_issue_comment,
      fn _token, _owner, _repo, _issue_number, _body -> {:ok, %{"id" => 1}} end
    )
  end

  defp setup_get_user_by_username do
    stub(
      Algora.GithubMock,
      :get_user_by_username,
      fn _token, username -> {:ok, %{"id" => 123, "login" => username}} end
    )
  end

  defp setup_get_issue do
    stub(
      Algora.GithubMock,
      :get_issue,
      fn _token, owner, repo, issue_number ->
        {:ok,
         %{
           "id" => 123,
           "number" => issue_number,
           "title" => "Test Issue",
           "body" => "Test body",
           "html_url" => "https://github.com/#{owner}/#{repo}/issues/#{issue_number}"
         }}
      end
    )
  end

  defp setup_get_repository do
    stub(
      Algora.GithubMock,
      :get_repository,
      fn _token, owner, repo ->
        {:ok,
         %{
           "id" => 123,
           "name" => repo,
           "html_url" => "https://github.com/#{owner}/#{repo}"
         }}
      end
    )
  end

  defp mock_body(s), do: "Lorem\r\nipsum\r\n dolor #{s} sit\r\namet"

  defp process_commands(event_action, command, author \\ @admin_user) do
    {event, action} = GithubController.split_event_action(event_action)
    entity = GithubController.get_entity_key(event)

    webhook = Map.put(@webhook, :event, event)

    params =
      @params
      |> Map.put(entity, %{"user" => %{"login" => author}, "body" => mock_body(command)})
      |> Map.put("action", action)

    GithubController.process_commands(
      webhook,
      event_action,
      GithubController.get_author(event, params),
      GithubController.get_body(event, params),
      params
    )
  end
end
