defmodule AlgoraWeb.WebhooksControllerTest do
  use AlgoraWeb.ConnCase
  import Mox
  alias AlgoraWeb.WebhooksController

  @base_url "https://api.github.com"

  @admin_user "jane"
  @unauthorized_user "john"
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

  # Updated setup block
  setup do
    # Mock the Finch client
    expect(Finch.Mock, :request, fn request, _finch_name ->
      case {request.method, request.url} do
        {:post, "https://api.github.com/app/installations/123/access_tokens"} ->
          {:ok,
           %Finch.Response{
             status: 201,
             body: Jason.encode!(%{"token" => "test_token"}),
             headers: [{"content-type", "application/json"}]
           }}

        {:get, "https://api.github.com/repos/owner/repo/collaborators/" <> rest} ->
          [user, "permission"] = String.split(rest, "/")
          permission = if user == @admin_user, do: "admin", else: "read"

          {:ok,
           %Finch.Response{
             status: 200,
             body: Jason.encode!(%{"permission" => permission}),
             headers: [{"content-type", "application/json"}]
           }}

        _ ->
          {:ok,
           %Finch.Response{
             status: 404,
             body: Jason.encode!(%{"message" => "Not Found"}),
             headers: [{"content-type", "application/json"}]
           }}
      end
    end)

    :ok
  end

  describe "bounty command" do
    test "handles bounty command without amount" do
      body = "/bounty"
      assert process_bounty_command(body) == [{:ok, :open_to_bids}]
    end

    test "handles valid bounty command with $ prefix" do
      body = "/bounty $100"
      assert process_bounty_command(body) == [{:ok, 100}]
    end

    test "handles invalid bounty command with $ suffix" do
      body = "/bounty 100$"
      assert process_bounty_command(body) == [{:ok, 100}]
    end

    test "handles bounty command without $ symbol" do
      body = "/bounty 100"
      assert process_bounty_command(body) == [{:ok, 100}]
    end

    test "handles bounty command with non-numeric amount" do
      body = "/bounty $abc"
      assert process_bounty_command(body) == [{:error, :invalid_format}]
    end

    test "handles bounty command with decimal amount" do
      body = "/bounty $100.50"
      assert process_bounty_command(body) == [{:error, :invalid_format}]
    end

    test "handles bounty command with unauthorized user" do
      body = "/bounty $100"
      assert process_bounty_command(body, @unauthorized_user) == [{:error, :unauthorized}]
    end
  end

  # Helper function to process bounty commands
  defp process_bounty_command(body, author \\ @admin_user) do
    full_body = """
    Lorem
    ipsum #{body} dolor
    sit
    amet
    """

    WebhooksController.process_commands(full_body, %{"login" => author}, @params)
  end
end
