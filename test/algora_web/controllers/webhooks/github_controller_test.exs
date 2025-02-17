defmodule AlgoraWeb.Webhooks.GithubControllerTest do
  use AlgoraWeb.ConnCase

  import Algora.Factory
  import AlgoraWeb.Webhooks.GithubController
  import Money.Sigil
  import Mox

  alias Algora.Bounties.Claim
  alias Algora.Github.Webhook
  alias Algora.Repo

  setup :verify_on_exit!

  setup(%{} = ctx) do
    admin = insert!(:user)
    unauthorized_user = insert!(:user)
    org = insert!(:organization)
    repository = insert!(:repository, user: org)
    installation = insert!(:installation, owner: admin, connected_user: org)

    user_type = ctx[:user_type] || :admin

    author =
      case user_type do
        :unauthorized -> unauthorized_user
        _ -> admin
      end

    event = ctx[:event] || "issue_comment"
    action = ctx[:action] || "created"
    body = ctx[:body] || ""

    ctx = %{
      user_type: user_type,
      admin: admin,
      author: author,
      org: org,
      installation: installation,
      repository: repository,
      event: event,
      action: action,
      body: body
    }

    webhook = mock_webhook(ctx)

    Map.put(ctx, :webhook, webhook)
  end

  describe "bounty command" do
    setup [:setup_github_mocks]

    @tag user_type: :unauthorized, body: "/bounty $100"
    test "handles bounty command with unauthorized user", context do
      assert {:error, :unauthorized} = process_commands(context[:webhook])
    end

    @tag body: "/bounty"
    test "handles bounty command without amount", context do
      assert {:ok, []} = process_commands(context[:webhook])
    end

    @tag body: "/bounty $100"
    test "handles valid bounty command with $ prefix", context do
      assert {:ok, [bounty]} = process_commands(context[:webhook])
      assert bounty.amount == ~M[100]usd
    end

    @tag body: "/bounty 100$"
    test "handles invalid bounty command with $ suffix", context do
      assert {:ok, [bounty]} = process_commands(context[:webhook])
      assert bounty.amount == ~M[100]usd
    end

    @tag body: "/bounty 100"
    test "handles bounty command without $ symbol", context do
      assert {:ok, [bounty]} = process_commands(context[:webhook])
      assert bounty.amount == ~M[100]usd
    end

    @tag body: "/bounty 100.50"
    test "handles bounty command with decimal amount", context do
      assert {:ok, [bounty]} = process_commands(context[:webhook])
      assert bounty.amount == ~M[100.50]usd
    end

    @tag body: "/bounty 100.5"
    test "handles bounty command with partial decimal amount", context do
      assert {:ok, [bounty]} = process_commands(context[:webhook])
      assert bounty.amount == ~M[100.5]usd
    end

    @tag body: "/bounty $100.50"
    test "handles bounty command with decimal amount and $ prefix", context do
      assert {:ok, [bounty]} = process_commands(context[:webhook])
      assert bounty.amount == ~M[100.50]usd
    end

    @tag body: "/bounty $100.5"
    test "handles bounty command with partial decimal amount and $ prefix", context do
      assert {:ok, [bounty]} = process_commands(context[:webhook])
      assert bounty.amount == ~M[100.5]usd
    end

    @tag body: "/bounty 100.50$"
    test "handles bounty command with decimal amount and $ suffix", context do
      assert {:ok, [bounty]} = process_commands(context[:webhook])
      assert bounty.amount == ~M[100.50]usd
    end

    @tag body: "/bounty 100.5$"
    test "handles bounty command with partial decimal amount and $ suffix", context do
      assert {:ok, [bounty]} = process_commands(context[:webhook])
      assert bounty.amount == ~M[100.5]usd
    end

    @tag body: "/bounty 1,000"
    test "handles bounty command with comma separator", context do
      assert {:ok, [bounty]} = process_commands(context[:webhook])
      assert bounty.amount == ~M[1000]usd
    end

    @tag body: "/bounty 1,000.50"
    test "handles bounty command with comma separator and decimal amount", context do
      assert {:ok, [bounty]} = process_commands(context[:webhook])
      assert bounty.amount == ~M[1000.50]usd
    end
  end

  describe "pull request closed event" do
    setup [:setup_github_mocks]

    @tag event: "pull_request", action: "closed"
    test "handles unmerged pull request", context do
      %{claim: claim, webhook: webhook} = setup_claim(context)
      webhook = put_in(webhook.payload["pull_request"]["merged_at"], nil)

      assert :ok == process_event(webhook)

      updated_claim = Repo.get(Claim, claim.id)
      assert updated_claim.status == :pending
    end

    @tag event: "pull_request", action: "closed"
    test "handles merged pull request with claims", context do
      %{claim: claim, webhook: webhook} = setup_claim(context)
      webhook = put_in(webhook.payload["pull_request"]["merged_at"], DateTime.to_iso8601(DateTime.utc_now()))

      assert :ok == process_event(webhook)

      updated_claim = Repo.get(Claim, claim.id)
      assert updated_claim.status == :approved
    end

    @tag event: "pull_request", action: "closed"
    test "handles merged pull request without claims", context do
      %{claim: claim, webhook: webhook} = setup_claim(context)

      webhook = put_in(webhook.payload["pull_request"]["merged_at"], DateTime.to_iso8601(DateTime.utc_now()))
      webhook = put_in(webhook.payload["pull_request"]["number"], claim.source.number + 1)

      assert :ok == process_event(webhook)

      updated_claim = Repo.get(Claim, claim.id)
      assert updated_claim.status == :pending
    end
  end

  defp setup_claim(context) do
    target = insert!(:ticket, repository: context[:repository])
    source = insert!(:ticket, repository: context[:repository])
    claim = insert!(:claim, user: context[:author], target: target, source: source, status: :pending)

    webhook = context[:webhook]
    webhook = put_in(webhook.payload["pull_request"]["number"], source.number)

    Map.merge(context, %{claim: claim, webhook: webhook})
  end

  defp setup_github_mocks(context) do
    setup_installation_token()
    setup_repository_permissions(context[:user_type])
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

  defp setup_repository_permissions(:admin) do
    stub(
      Algora.GithubMock,
      :get_repository_permissions,
      fn _token, _owner, _repo, _user -> {:ok, %{"permission" => "admin"}} end
    )
  end

  defp setup_repository_permissions(:unauthorized) do
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

  defp mock_body(body \\ ""), do: "Lorem\r\nipsum\r\n dolor #{body} sit\r\namet"

  defp mock_user(user) do
    %{
      "id" => String.to_integer(user.provider_id),
      "login" => user.provider_login
    }
  end

  defp mock_webhook(context) do
    webhook_body = mock_body(context[:body])
    webhook_author = mock_user(context[:author])
    payload = mock_payload(context)

    %Webhook{
      event: context[:event],
      event_action: "#{context[:event]}.#{context[:action]}",
      hook_id: "123456789",
      delivery: "00000000-0000-0000-0000-000000000000",
      signature: "sha1=0000000000000000000000000000000000000000",
      signature_256: "sha256=0000000000000000000000000000000000000000000000000000000000000000",
      user_agent: "GitHub-Hookshot/0000000",
      installation_target_type: "integration",
      installation_target_id: "123456",
      payload: payload,
      body: webhook_body,
      author: webhook_author
    }
  end

  defp mock_base_payload(context) do
    %{
      "action" => context[:action],
      "repository" => %{
        "id" => String.to_integer(context[:repository].provider_id),
        "owner" => %{
          "id" => String.to_integer(context[:org].provider_id),
          "login" => context[:org].provider_login
        },
        "name" => context[:repository].name
      },
      "installation" => %{
        "id" => String.to_integer(context[:installation].provider_id)
      },
      Webhook.entity_key(context[:event]) => %{
        "number" => 123,
        "body" => "Lorem\r\nipsum\r\n dolor #{context[:body]} sit\r\namet",
        "user" => %{
          "id" => String.to_integer(context[:author].provider_id),
          "login" => context[:author].provider_login
        }
      }
    }
  end

  defp mock_payload(%{event: "issue_comment"} = context) do
    context
    |> mock_base_payload()
    |> Map.merge(%{
      "comment" => %{
        "id" => 123,
        "body" => mock_body(context[:body]),
        "user" => mock_user(context[:author])
      },
      "issue" => %{
        "id" => 123,
        "number" => 123,
        "body" => mock_body(),
        "user" => mock_user(context[:admin])
      }
    })
  end

  defp mock_payload(%{event: "issues"} = context) do
    context
    |> mock_base_payload()
    |> Map.put("issue", %{
      "id" => 123,
      "number" => 123,
      "body" => mock_body(context[:body]),
      "user" => mock_user(context[:author])
    })
  end

  defp mock_payload(%{event: "pull_request"} = context) do
    context
    |> mock_base_payload()
    |> Map.put("pull_request", %{
      "id" => 123,
      "number" => 123,
      "body" => mock_body(context[:body]),
      "user" => mock_user(context[:author])
    })
  end
end
