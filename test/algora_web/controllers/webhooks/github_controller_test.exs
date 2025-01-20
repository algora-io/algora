defmodule AlgoraWeb.Webhooks.GithubControllerTest do
  use AlgoraWeb.ConnCase

  import Algora.Factory
  import Money.Sigil
  import Mox

  alias Algora.Github.Webhook
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
      assert {:error, :unauthorized} = process_bounty_command("/bounty $100", user)
    end

    test "handles bounty command without amount" do
      assert {:ok, []} = process_bounty_command("/bounty")
    end

    test "handles valid bounty command with $ prefix" do
      assert {:ok, [bounty]} = process_bounty_command("/bounty $100")
      assert bounty.amount == ~M[100]usd
    end

    test "handles invalid bounty command with $ suffix" do
      assert {:ok, [bounty]} = process_bounty_command("/bounty 100$")
      assert bounty.amount == ~M[100]usd
    end

    test "handles bounty command without $ symbol" do
      assert {:ok, [bounty]} = process_bounty_command("/bounty 100")
      assert bounty.amount == ~M[100]usd
    end

    test "handles bounty command with decimal amount" do
      assert {:ok, [bounty]} = process_bounty_command("/bounty 100.50")
      assert bounty.amount == ~M[100.50]usd
    end

    test "handles bounty command with partial decimal amount" do
      assert {:ok, [bounty]} = process_bounty_command("/bounty 100.5")
      assert bounty.amount == ~M[100.5]usd
    end

    test "handles bounty command with decimal amount and $ prefix" do
      assert {:ok, [bounty]} = process_bounty_command("/bounty $100.50")
      assert bounty.amount == ~M[100.50]usd
    end

    test "handles bounty command with partial decimal amount and $ prefix" do
      assert {:ok, [bounty]} = process_bounty_command("/bounty $100.5")
      assert bounty.amount == ~M[100.5]usd
    end

    test "handles bounty command with decimal amount and $ suffix" do
      assert {:ok, [bounty]} = process_bounty_command("/bounty 100.50$")
      assert bounty.amount == ~M[100.50]usd
    end

    test "handles bounty command with partial decimal amount and $ suffix" do
      assert {:ok, [bounty]} = process_bounty_command("/bounty 100.5$")
      assert bounty.amount == ~M[100.5]usd
    end

    test "handles bounty command with comma separator" do
      assert {:ok, [bounty]} = process_bounty_command("/bounty 1,000")
      assert bounty.amount == ~M[1000]usd
    end

    test "handles bounty command with comma separator and decimal amount" do
      assert {:ok, [bounty]} = process_bounty_command("/bounty 1,000.50")
      assert bounty.amount == ~M[1000.50]usd
    end
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

  # Helper function to process bounty commands
  defp process_bounty_command(command, author \\ @admin_user) do
    body = """
    Lorem
    ipsum #{command} dolor
    sit
    amet
    """

    GithubController.process_commands(
      @webhook,
      Map.put(@params, "comment", %{"user" => %{"login" => author}, "body" => body})
    )
  end
end
