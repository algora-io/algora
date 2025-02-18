defmodule AlgoraWeb.Webhooks.GithubControllerTest do
  use AlgoraWeb.ConnCase
  use ExMachina.Ecto, repo: Algora.Repo
  use Oban.Testing, repo: Algora.Repo

  import Algora.Factory
  import Ecto.Query
  import ExUnit.CaptureLog
  import Money.Sigil

  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Jobs.NotifyBounty
  alias Algora.Github.Webhook
  alias Algora.Repo
  alias AlgoraWeb.Webhooks.GithubController

  setup do
    admin = insert!(:user, provider_login: sequence(:provider_login, &"admin#{&1}"))
    unauthorized_user = insert!(:user, provider_login: sequence(:provider_login, &"unauthorized#{&1}"))
    org = insert!(:organization)
    repository = insert!(:repository, user: org)
    installation = insert!(:installation, owner: admin, connected_user: org)

    %{
      admin: admin,
      unauthorized_user: unauthorized_user,
      org: org,
      installation: installation,
      repository: repository
    }
  end

  describe "create bounties" do
    test "handles bounty command with unauthorized user", ctx do
      scenario = [%{event_action: "issue_comment.created", user_type: :unauthorized, body: "/bounty $100"}]
      {result, _log} = with_log(fn -> process_scenario(ctx, scenario) end)
      assert {:error, :unauthorized} = result
      assert Repo.aggregate(Bounty, :count) == 0
    end

    test "handles bounty command without amount", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty"}])
      assert Repo.aggregate(Bounty, :count) == 0
    end

    test "handles bounty command with $ prefix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty $100"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)
    end

    test "handles bounty command with $ suffix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty 100$"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)
    end

    test "handles bounty command without $ symbol", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty 100"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)
    end

    test "handles bounty command with decimal amount", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty 100.50"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.50]usd)
    end

    test "handles bounty command with partial decimal amount", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty 100.5"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.5]usd)
    end

    test "handles bounty command with decimal amount and $ prefix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty $100.50"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.50]usd)
    end

    test "handles bounty command with partial decimal amount and $ prefix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty $100.5"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.5]usd)
    end

    test "handles bounty command with decimal amount and $ suffix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty 100.50$"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.50]usd)
    end

    test "handles bounty command with partial decimal amount and $ suffix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty 100.5$"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.5]usd)
    end

    test "handles bounty command with comma separator", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty 1,000"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[1000]usd)
    end

    test "handles bounty command with comma separator and decimal amount", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :admin, body: "/bounty 1,000.50"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[1000.50]usd)
    end
  end

  describe "edit bounties" do
    test "updates bounty amount when editing the original bounty comment", ctx do
      comment_id = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $100",
          params: %{"id" => comment_id}
        }
      ])

      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)

      assert [job] = all_enqueued(worker: NotifyBounty)
      assert {:ok, _} = perform_job(NotifyBounty, job.args)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.edited",
          user_type: :admin,
          body: "/bounty $200",
          params: %{"id" => comment_id}
        }
      ])

      assert Money.equal?(Repo.one(Bounty).amount, ~M[200]usd)
    end

    test "adds to bounty amount when creating a new bounty comment", ctx do
      comment_id = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $100",
          params: %{"id" => comment_id}
        }
      ])

      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)

      assert [job] = all_enqueued(worker: NotifyBounty)
      assert {:ok, _} = perform_job(NotifyBounty, job.args)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $200",
          params: %{"id" => comment_id + 1}
        }
      ])

      assert Money.equal?(Repo.one(Bounty).amount, ~M[300]usd)
    end
  end

  describe "create claims" do
    test "creates claims with split shares", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $100",
          params: %{"number" => issue_number}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number} /split @jsmith /split @jdoe",
          params: %{"number" => pr_number}
        }
      ])

      claims = Repo.all(Claim)

      assert length(claims) == 3
      assert Enum.all?(claims, &(&1.group_share == Decimal.div(1, 3)))
      assert Enum.all?(claims, &(&1.group_id == hd(claims).group_id))
      assert Enum.all?(claims, &(&1.source_id == hd(claims).source_id))
      assert Enum.all?(claims, &(&1.target_id == hd(claims).target_id))
    end

    test "claim command is idempotent when editing pull request", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $100",
          params: %{"number" => issue_number}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"number" => pr_number}
        },
        %{
          event_action: "pull_request.edited",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"number" => pr_number}
        }
      ])

      assert Repo.aggregate(Claim, :count) == 1
    end

    test "does not allow multiple claims in a single PR", ctx do
      issue_number1 = :rand.uniform(1000)
      issue_number2 = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $100",
          params: %{"number" => issue_number1}
        },
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $100",
          params: %{"number" => issue_number2}
        }
      ])

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number1} /claim #{issue_number2}",
          params: %{"number" => pr_number}
        }
      ])

      assert Repo.aggregate(Claim, :count) == 1
    end

    test "cancels existing claim when attempting to claim a different bounty in the same PR", ctx do
      issue_number1 = :rand.uniform(1000)
      issue_number2 = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $100",
          params: %{"number" => issue_number1}
        }
      ])

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number1}",
          params: %{"number" => pr_number}
        }
      ])

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number2}",
          params: %{"number" => pr_number}
        }
      ])

      claims = Repo.all(from c in Claim, where: c.status != :cancelled)
      assert length(claims) == 1

      claims = Repo.all(from c in Claim, where: c.status == :cancelled)
      assert length(claims) == 1
    end

    test "handles claim lifecycle with splits and cancellations", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $100",
          params: %{"number" => issue_number}
        }
      ])

      assert Repo.aggregate(Claim, :count) == 0

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"number" => pr_number}
        }
      ])

      claims = Repo.all(Claim)
      assert length(claims) == 1

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.edited",
          user_type: :unauthorized,
          body: "/claim #{issue_number} /split @jsmith",
          params: %{"number" => pr_number}
        }
      ])

      claims = Repo.all(Claim)

      assert length(claims) == 2
      assert Enum.all?(claims, &(&1.group_share == Decimal.div(1, 2)))
      assert Enum.all?(claims, &(&1.group_id == hd(claims).group_id))
      assert Enum.all?(claims, &(&1.source_id == hd(claims).source_id))
      assert Enum.all?(claims, &(&1.target_id == hd(claims).target_id))

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.edited",
          user_type: :unauthorized,
          body: "/claim #{issue_number} /split @jdoe",
          params: %{"number" => pr_number}
        }
      ])

      cancelled_claims = Repo.all(from c in Claim, where: c.status == :cancelled)
      assert length(cancelled_claims) == 1

      claims = Repo.all(from c in Claim, where: c.status != :cancelled)
      assert length(claims) == 2
      assert Enum.all?(claims, &(&1.group_share == Decimal.div(1, 2)))
      assert Enum.all?(claims, &(&1.group_id == hd(claims).group_id))
      assert Enum.all?(claims, &(&1.source_id == hd(claims).source_id))
      assert Enum.all?(claims, &(&1.target_id == hd(claims).target_id))

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.edited",
          user_type: :unauthorized,
          body: "",
          params: %{"number" => pr_number}
        }
      ])

      cancelled_claims = Repo.all(from c in Claim, where: c.status == :cancelled)
      assert length(cancelled_claims) == 3

      claims = Repo.all(from c in Claim, where: c.status != :cancelled)
      assert length(claims) == 0
    end
  end

  describe "pull request closed event" do
    test "handles unmerged pull request", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $100",
          params: %{"number" => issue_number}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"number" => pr_number}
        },
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"number" => pr_number, "merged_at" => nil}
        }
      ])

      assert Repo.one(Claim).status == :pending
    end

    test "handles merged pull request with claims", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $100",
          params: %{"number" => issue_number}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"number" => pr_number}
        },
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"number" => pr_number, "merged_at" => DateTime.to_iso8601(DateTime.utc_now())}
        }
      ])

      assert Repo.one(Claim).status == :approved
    end

    test "handles merged pull request without claims", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :admin,
          body: "/bounty $100",
          params: %{"number" => issue_number}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "fixes #{issue_number}",
          params: %{"number" => pr_number}
        },
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "fixes #{issue_number}",
          params: %{"number" => pr_number, "merged_at" => DateTime.to_iso8601(DateTime.utc_now())}
        }
      ])

      assert Repo.aggregate(Claim, :count) == 0
    end
  end

  defp mock_body(body \\ ""), do: "Lorem\r\nipsum\r\n dolor #{body} sit\r\namet"

  defp mock_user(user) do
    %{
      "id" => String.to_integer(user.provider_id),
      "login" => user.provider_login
    }
  end

  defp mock_webhook(ctx) do
    author =
      case ctx[:user_type] do
        :unauthorized -> ctx[:unauthorized_user]
        _ -> ctx[:admin]
      end

    [event, action] = String.split(ctx[:event_action], ".")

    ctx = Map.merge(ctx, %{event: event, action: action, author: author, params: ctx[:params] || %{}})

    %Webhook{
      event: event,
      event_action: "#{event}.#{action}",
      hook_id: "123456789",
      delivery: "00000000-0000-0000-0000-000000000000",
      signature: "sha1=0000000000000000000000000000000000000000",
      signature_256: "sha256=0000000000000000000000000000000000000000000000000000000000000000",
      user_agent: "GitHub-Hookshot/0000000",
      installation_target_type: "integration",
      installation_target_id: "123456",
      payload: mock_payload(ctx),
      body: mock_body(ctx[:body]),
      author: mock_user(author)
    }
  end

  defp mock_base_payload(ctx) do
    %{
      "action" => ctx[:action],
      "repository" => %{
        "id" => String.to_integer(ctx[:repository].provider_id),
        "owner" => %{
          "id" => String.to_integer(ctx[:org].provider_id),
          "login" => ctx[:org].provider_login
        },
        "name" => ctx[:repository].name
      },
      "installation" => %{
        "id" => String.to_integer(ctx[:installation].provider_id)
      }
    }
  end

  defp mock_payload(%{event: "issue_comment"} = ctx) do
    ctx
    |> mock_base_payload()
    |> Map.merge(%{
      "comment" =>
        Map.merge(
          %{
            "id" => 123,
            "body" => mock_body(ctx[:body]),
            "user" => mock_user(ctx[:author])
          },
          ctx[:params]
        ),
      "issue" => %{
        "id" => 123,
        "number" => 123,
        "body" => mock_body(),
        "user" => mock_user(ctx[:admin])
      }
    })
  end

  defp mock_payload(%{event: "issues"} = ctx) do
    ctx
    |> mock_base_payload()
    |> Map.put(
      "issue",
      Map.merge(
        %{
          "id" => 123,
          "number" => 123,
          "body" => mock_body(ctx[:body]),
          "user" => mock_user(ctx[:author])
        },
        ctx[:params]
      )
    )
  end

  defp mock_payload(%{event: "pull_request"} = ctx) do
    ctx
    |> mock_base_payload()
    |> Map.put(
      "pull_request",
      Map.merge(
        %{
          "id" => 123,
          "number" => 123,
          "body" => mock_body(ctx[:body]),
          "user" => mock_user(ctx[:author]),
          "merged_at" => nil
        },
        ctx[:params]
      )
    )
  end

  defp process_scenario(ctx, scenario) do
    Enum.reduce_while(
      scenario,
      :ok,
      fn opts, :ok ->
        case ctx |> Map.merge(opts) |> mock_webhook() |> GithubController.process_delivery() do
          :ok -> {:cont, :ok}
          error -> {:halt, error}
        end
      end
    )
  end

  defp process_scenario!(ctx, scenario) do
    :ok = process_scenario(ctx, scenario)
  end
end
