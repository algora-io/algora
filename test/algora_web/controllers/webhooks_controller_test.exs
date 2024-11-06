defmodule AlgoraWeb.WebhooksControllerTest do
  use AlgoraWeb.ConnCase
  import Mox

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
    "installation" => %{
      "id" => @installation_id
    }
  }

  describe "bounty command" do
    setup [:setup_github_mocks]

    @tag user: @unauthorized_user
    test "handles bounty command with unauthorized user", %{user: user} do
      assert [error: :unauthorized] = process_bounty_command("/bounty", user)
    end

    test "handles bounty command without amount" do
      assert [ok: :open_to_bids] = process_bounty_command("/bounty")
    end

    test "handles valid bounty command with $ prefix" do
      assert [ok: 100] = process_bounty_command("/bounty $100")
    end

    test "handles invalid bounty command with $ suffix" do
      assert [ok: 100] = process_bounty_command("/bounty 100$")
    end

    test "handles bounty command without $ symbol" do
      assert [ok: 100] = process_bounty_command("/bounty 100")
    end

    test "handles bounty command with decimal amount" do
      assert [ok: 100] = process_bounty_command("/bounty 100.50")
    end

    test "handles bounty command with partial decimal amount" do
      assert [ok: 100] = process_bounty_command("/bounty 100.5")
    end

    test "handles bounty command with decimal amount and $ prefix" do
      assert [ok: 100] = process_bounty_command("/bounty $100.50")
    end

    test "handles bounty command with partial decimal amount and $ prefix" do
      assert [ok: 100] = process_bounty_command("/bounty $100.5")
    end

    test "handles bounty command with decimal amount and $ suffix" do
      assert [ok: 100] = process_bounty_command("/bounty 100.50$")
    end

    test "handles bounty command with partial decimal amount and $ suffix" do
      assert [ok: 100] = process_bounty_command("/bounty 100.5$")
    end

    test "handles bounty command with comma separator" do
      assert [ok: 1000] = process_bounty_command("/bounty 1,000")
    end

    test "handles bounty command with comma separator and decimal amount" do
      assert [ok: 1000] = process_bounty_command("/bounty 1,000.50")
    end
  end

  defp setup_github_mocks(context) do
    setup_installation_token()
    setup_repository_permissions(context[:user] || @admin_user)
    :ok
  end

  defp setup_installation_token do
    expect(
      Algora.Github.MockClient,
      :get_installation_token,
      fn _installation_id -> {:ok, %{"token" => "test_token"}} end
    )
  end

  defp setup_repository_permissions(@admin_user) do
    expect(
      Algora.Github.MockClient,
      :get_repository_permissions,
      fn _token, _owner, _repo, _user -> {:ok, %{"permission" => "admin"}} end
    )
  end

  defp setup_repository_permissions(@unauthorized_user) do
    expect(
      Algora.Github.MockClient,
      :get_repository_permissions,
      fn _token, _owner, _repo, _user -> {:ok, %{"permission" => "none"}} end
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

    AlgoraWeb.WebhooksController.process_commands(full_body, %{"login" => author}, @params)
  end
end
