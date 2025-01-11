defmodule AlgoraWeb.Webhooks.GithubControllerTest do
  use AlgoraWeb.ConnCase

  import Algora.Factory
  import Money.Sigil
  import Mox

  alias AlgoraWeb.Webhooks.GithubController

  setup :verify_on_exit!

  @admin_user "jsmith"
  @unauthorized_user "jdoe"
  @repo_owner "owner"
  @repo_name "repo"
  @installation_id 123

  @params %{
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
      assert process_bounty_command("/bounty $100", user)[:ok] == nil
      assert process_bounty_command("/bounty $100", user)[:error] == :unauthorized
    end

    test "handles bounty command without amount" do
      assert process_bounty_command("/bounty")[:ok] == nil
      assert process_bounty_command("/bounty")[:error] == nil
    end

    test "handles valid bounty command with $ prefix" do
      assert process_bounty_command("/bounty $100")[:ok].amount == ~M[100]usd
    end

    test "handles invalid bounty command with $ suffix" do
      assert process_bounty_command("/bounty 100$")[:ok].amount == ~M[100]usd
    end

    test "handles bounty command without $ symbol" do
      assert process_bounty_command("/bounty 100")[:ok].amount == ~M[100]usd
    end

    test "handles bounty command with decimal amount" do
      assert process_bounty_command("/bounty 100.50")[:ok].amount == ~M[100.50]usd
    end

    test "handles bounty command with partial decimal amount" do
      assert process_bounty_command("/bounty 100.5")[:ok].amount == ~M[100.5]usd
    end

    test "handles bounty command with decimal amount and $ prefix" do
      assert process_bounty_command("/bounty $100.50")[:ok].amount == ~M[100.50]usd
    end

    test "handles bounty command with partial decimal amount and $ prefix" do
      assert process_bounty_command("/bounty $100.5")[:ok].amount == ~M[100.5]usd
    end

    test "handles bounty command with decimal amount and $ suffix" do
      assert process_bounty_command("/bounty 100.50$")[:ok].amount == ~M[100.50]usd
    end

    test "handles bounty command with partial decimal amount and $ suffix" do
      assert process_bounty_command("/bounty 100.5$")[:ok].amount == ~M[100.5]usd
    end

    test "handles bounty command with comma separator" do
      assert process_bounty_command("/bounty 1,000")[:ok].amount == ~M[1000]usd
    end

    test "handles bounty command with comma separator and decimal amount" do
      assert process_bounty_command("/bounty 1,000.50")[:ok].amount == ~M[1000.50]usd
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
  defp process_bounty_command(body, author \\ @admin_user) do
    full_body = """
    Lorem
    ipsum #{body} dolor
    sit
    amet
    """

    GithubController.process_commands(full_body, %{"login" => author}, @params)
  end
end
