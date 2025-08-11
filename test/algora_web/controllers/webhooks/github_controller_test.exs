defmodule AlgoraWeb.Webhooks.GithubControllerTest do
  use AlgoraWeb.ConnCase
  use ExMachina.Ecto, repo: Algora.Repo
  use Oban.Testing, repo: Algora.Repo

  import Algora.Factory
  import Ecto.Changeset
  import Ecto.Query
  import ExUnit.CaptureLog
  import Money.Sigil

  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Jobs.NotifyBounty
  alias Algora.Bounties.Jobs.NotifyTipIntent
  alias Algora.Bounties.Tip
  alias Algora.Github.Webhook
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Workspace.Ticket
  alias AlgoraWeb.Webhooks.GithubController

  setup do
    unauthorized_user = insert!(:user, provider_login: sequence(:provider_login, &"unauthorized#{&1}"))
    repo_admin = insert!(:user, provider_login: sequence(:provider_login, &"admin#{&1}"))
    org_admin = insert!(:user)
    org_mod = insert!(:user)
    org_expert = insert!(:user)

    org = insert!(:organization)
    insert!(:member, user: org_admin, org: org, role: :admin)
    insert!(:member, user: org_mod, org: org, role: :mod)
    insert!(:member, user: org_expert, org: org, role: :expert)

    repository = insert!(:repository, user: org)
    installation = insert!(:installation, owner: repo_admin, connected_user: org)

    %{
      repo_admin: repo_admin,
      org_admin: org_admin,
      org_mod: org_mod,
      org_expert: org_expert,
      unauthorized_user: unauthorized_user,
      org: org,
      installation: installation,
      repository: repository
    }
  end

  describe "create bounties" do
    test "handles bounty command as unauthorized user", ctx do
      scenario = [%{event_action: "issue_comment.created", user_type: :unauthorized, body: "/bounty $100"}]
      {result, _log} = with_log(fn -> process_scenario(ctx, scenario) end)
      assert {:error, :unauthorized} = result
      assert Repo.aggregate(Bounty, :count) == 0
    end

    test "handles bounty command as org expert", ctx do
      scenario = [%{event_action: "issue_comment.created", user_type: :unauthorized, body: "/bounty $100"}]
      {result, _log} = with_log(fn -> process_scenario(ctx, scenario) end)
      assert {:error, :unauthorized} = result
      assert Repo.aggregate(Bounty, :count) == 0
    end

    test "handles bounty command as org mod", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :org_mod, body: "/bounty $100"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)
    end

    test "handles bounty command as org admin", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :org_admin, body: "/bounty $100"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)
    end

    test "handles bounty command without amount", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty"}])
      assert Repo.aggregate(Bounty, :count) == 0
    end

    test "handles bounty command with $ prefix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty $100"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)
    end

    test "handles bounty command with $ suffix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty 100$"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)
    end

    test "handles bounty command without $ symbol", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty 100"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)
    end

    test "handles bounty command with decimal amount", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty 100.50"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.50]usd)
    end

    test "handles bounty command with partial decimal amount", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty 100.5"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.5]usd)
    end

    test "handles bounty command with decimal amount and $ prefix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty $100.50"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.50]usd)
    end

    test "handles bounty command with partial decimal amount and $ prefix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty $100.5"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.5]usd)
    end

    test "handles bounty command with decimal amount and $ suffix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty 100.50$"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.50]usd)
    end

    test "handles bounty command with partial decimal amount and $ suffix", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty 100.5$"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[100.5]usd)
    end

    test "handles bounty command with comma separator", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty 1,000"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[1000]usd)
    end

    test "handles bounty command with comma separator and decimal amount", ctx do
      process_scenario!(ctx, [%{event_action: "issue_comment.created", user_type: :repo_admin, body: "/bounty 1,000.50"}])
      assert Money.equal?(Repo.one(Bounty).amount, ~M[1000.50]usd)
    end
  end

  describe "edit bounties" do
    test "updates bounty amount when editing the original bounty comment", ctx do
      comment_id = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"comment" => %{"id" => comment_id}}
        }
      ])

      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)

      assert [job] = all_enqueued(worker: NotifyBounty)
      assert {:ok, _} = perform_job(NotifyBounty, job.args)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.edited",
          user_type: :repo_admin,
          body: "/bounty $200",
          params: %{"comment" => %{"id" => comment_id}}
        }
      ])

      assert Money.equal?(Repo.one(Bounty).amount, ~M[200]usd)
    end

    test "adds to bounty amount when creating a new bounty comment", ctx do
      comment_id = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"comment" => %{"id" => comment_id}}
        }
      ])

      assert Money.equal?(Repo.one(Bounty).amount, ~M[100]usd)

      assert [job] = all_enqueued(worker: NotifyBounty)
      assert {:ok, _} = perform_job(NotifyBounty, job.args)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $200",
          params: %{"comment" => %{"id" => comment_id + 1}}
        }
      ])

      assert Money.equal?(Repo.one(Bounty).amount, ~M[300]usd)
    end

    test "editing GitHub comment with /bounty command preserves bounty visibility", ctx do
      comment_id = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"comment" => %{"id" => comment_id}}
        }
      ])

      bounty = Repo.one(Bounty)
      original_visibility = bounty.visibility
      assert original_visibility

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.edited",
          user_type: :repo_admin,
          body: "/bounty $200",
          params: %{"comment" => %{"id" => comment_id}}
        }
      ])

      updated_bounty = Repo.one(Bounty)
      assert updated_bounty.visibility == original_visibility
    end

    test "visibility preserved when adding to existing bounty via new comment", ctx do
      # Create initial bounty with exclusive visibility
      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $500",
          params: %{"comment" => %{"id" => 1}}
        }
      ])

      original_bounty = Repo.one(Bounty)
      # Set to exclusive mode for this test
      _updated_owner = ctx[:org] |> change(%{bounty_mode: :exclusive}) |> Repo.update!()
      updated_bounty = original_bounty |> change(%{visibility: :exclusive}) |> Repo.update!()

      original_visibility = updated_bounty.visibility
      assert original_visibility == :exclusive

      # Add to bounty with new comment (this increases the amount)
      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"comment" => %{"id" => 2}}
        }
      ])

      final_bounty = Repo.one(Bounty)
      assert final_bounty.amount.amount >= 600

      # This test should now PASS with the fix - visibility is preserved
      assert final_bounty.visibility == original_visibility
    end

    test "updates ticket title and description on issues.edited", ctx do
      issue_number = :rand.uniform(1000)
      updated_title = "Updated Issue Title"
      updated_body = "Updated issue description"

      # First create the issue (title will be set by GitHub mock to "title #{number}")
      process_scenario!(ctx, [
        %{
          event_action: "issues.opened",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{
            "issue" => %{
              "number" => issue_number,
              "state" => "open"
            }
          }
        }
      ])

      ticket = Repo.get_by!(Ticket, number: issue_number)
      # This comes from GitHub mock
      assert ticket.title == "title #{issue_number}"
      # This comes from GitHub mock
      assert ticket.description == "body #{issue_number}"

      # Now edit the issue title and description
      process_scenario!(ctx, [
        %{
          event_action: "issues.edited",
          user_type: :repo_admin,
          params: %{
            "issue" => %{
              "number" => issue_number,
              "state" => "open",
              "title" => updated_title,
              "body" => updated_body
            }
          }
        }
      ])

      ticket = Repo.get_by!(Ticket, number: issue_number)
      assert ticket.title == updated_title
      assert ticket.description == updated_body
    end
  end

  describe "create tips" do
    test "rejects tip command when user is unauthorized", ctx do
      scenario = [
        %{
          event_action: "issue_comment.created",
          user_type: :unauthorized,
          body: "/tip $100 @jsmith"
        }
      ]

      {result, _log} = with_log(fn -> process_scenario(ctx, scenario) end)
      assert {:error, :unauthorized} = result

      assert [] = all_enqueued(worker: NotifyTipIntent)
    end

    test "generates tip payment link when amount and recipient are provided in correct order", ctx do
      issue_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip $100 @jsmith",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      assert [job] = all_enqueued(worker: NotifyTipIntent)
      assert {:ok, _comment} = perform_job(NotifyTipIntent, job.args)

      assert job.args["body"] =~
               "Please visit [Algora](#{AlgoraWeb.Endpoint.url()}/tip?amount=100&recipient=jsmith&owner=#{ctx[:org].provider_login}&repo=#{ctx[:repository].name}&number=#{issue_number}&org_id=#{ctx[:installation].connected_user_id}) to complete your tip via Stripe."
    end

    test "generates tip payment link when recipient and amount are provided in reverse order", ctx do
      issue_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip @jsmith $100",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      assert [job] = all_enqueued(worker: NotifyTipIntent)
      assert {:ok, _comment} = perform_job(NotifyTipIntent, job.args)

      assert job.args["body"] =~
               "Please visit [Algora](#{AlgoraWeb.Endpoint.url()}/tip?amount=100&recipient=jsmith&owner=#{ctx[:org].provider_login}&repo=#{ctx[:repository].name}&number=#{issue_number}&org_id=#{ctx[:installation].connected_user_id}) to complete your tip via Stripe."
    end

    test "generates tip payment link when amount is provided and recipient is inferred from issue", ctx do
      issue_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip $100",
          params: %{"issue" => %{"number" => issue_number, "user" => %{"login" => "jsmith"}}}
        }
      ])

      assert [job] = all_enqueued(worker: NotifyTipIntent)
      assert {:ok, _comment} = perform_job(NotifyTipIntent, job.args)

      assert job.args["body"] =~
               "Please visit [Algora](#{AlgoraWeb.Endpoint.url()}/tip?amount=100&recipient=jsmith&owner=#{ctx[:org].provider_login}&repo=#{ctx[:repository].name}&number=#{issue_number}&org_id=#{ctx[:installation].connected_user_id}) to complete your tip via Stripe."
    end

    test "prompts for recipient when attempting to tip issue author who is the tipper", ctx do
      issue_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip $100",
          params: %{"issue" => %{"number" => issue_number, "user" => %{"login" => ctx[:repo_admin].provider_login}}}
        }
      ])

      assert [job] = all_enqueued(worker: NotifyTipIntent)
      assert {:ok, _comment} = perform_job(NotifyTipIntent, job.args)

      assert job.args["body"] =~ "Please specify a recipient to tip (e.g. `/tip $100 @jsmith`)"
    end

    test "prompts for amount when only recipient is provided", ctx do
      issue_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip @jsmith",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      assert [job] = all_enqueued(worker: NotifyTipIntent)
      assert {:ok, _comment} = perform_job(NotifyTipIntent, job.args)

      assert job.args["body"] =~ "Please specify an amount to tip (e.g. `/tip $100 @jsmith`)"
    end

    test "handles autopay", ctx do
      issue_number = :rand.uniform(1000)

      customer = insert!(:customer, user: ctx[:org])
      _payment_method = insert!(:payment_method, is_default: true, customer: customer)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip $100 @#{ctx[:unauthorized_user].provider_login}",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      tip = Repo.one!(Tip)

      charge = Repo.one!(from t in Transaction, where: t.type == :charge)
      assert Money.equal?(charge.net_amount, Money.new(:USD, 100))
      assert charge.status == :initialized
      assert charge.user_id == ctx[:org].id

      debit = Repo.one!(from t in Transaction, where: t.type == :debit)
      assert Money.equal?(debit.net_amount, Money.new(:USD, 100))
      assert debit.status == :initialized
      assert debit.user_id == ctx[:org].id
      assert debit.tip_id == tip.id

      credit = Repo.one!(from t in Transaction, where: t.type == :credit)
      assert Money.equal?(credit.net_amount, Money.new(:USD, 100))
      assert credit.status == :initialized
      assert credit.user_id == ctx[:unauthorized_user].id
      assert credit.tip_id == tip.id

      transfer = Repo.one(from t in Transaction, where: t.type == :transfer)
      assert is_nil(transfer)
    end

    test "does not autopay when payment method is not default", ctx do
      issue_number = :rand.uniform(1000)

      customer = insert!(:customer, user: ctx[:org])
      _payment_method = insert!(:payment_method, is_default: false, customer: customer)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip $100 @#{ctx[:unauthorized_user].provider_login}",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      assert Repo.aggregate(Transaction, :count) == 0
      assert_enqueued(worker: NotifyTipIntent)
    end

    test "respects cooldown period for autopay tips to same recipient", ctx do
      issue_number = :rand.uniform(1000)

      customer = insert!(:customer, user: ctx[:org])
      _payment_method = insert!(:payment_method, is_default: true, customer: customer)

      # Create first tip
      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip $100 @#{ctx[:unauthorized_user].provider_login}",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      # First tip should be autopaid
      # charge, debit, credit
      assert Repo.aggregate(Transaction, :count) == 3

      # Try to create second tip within cooldown period
      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip $50 @#{ctx[:unauthorized_user].provider_login}",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      # Second tip should not be autopaid, transaction count should remain same
      assert Repo.aggregate(Transaction, :count) == 3
      assert_enqueued(worker: NotifyTipIntent)
    end

    test "allows autopay after cooldown period expires", ctx do
      issue_number = :rand.uniform(1000)

      customer = insert!(:customer, user: ctx[:org])
      _payment_method = insert!(:payment_method, is_default: true, customer: customer)

      # Create first tip
      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip $100 @#{ctx[:unauthorized_user].provider_login}",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      # First tip should be autopaid
      # charge, debit, credit
      assert Repo.aggregate(Transaction, :count) == 3

      # Simulate passage of time beyond cooldown period
      first_tip = Repo.one!(Tip)

      Repo.update!(
        Ecto.Changeset.change(first_tip,
          inserted_at: DateTime.add(first_tip.inserted_at, -(to_timeout(hour: 1) + 1), :millisecond)
        )
      )

      # Create second tip after cooldown
      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip $50 @#{ctx[:unauthorized_user].provider_login}",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      # Second tip should be autopaid, transaction count should increase
      # 2 sets of charge, debit, credit
      assert Repo.aggregate(Transaction, :count) == 6
      refute_enqueued(worker: NotifyTipIntent)
    end

    test "cooldown applies per recipient", ctx do
      issue_number = :rand.uniform(1000)
      other_user = insert!(:user)

      customer = insert!(:customer, user: ctx[:org])
      _payment_method = insert!(:payment_method, is_default: true, customer: customer)

      # Create tip for first recipient
      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip $100 @#{ctx[:unauthorized_user].provider_login}",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      # First tip should be autopaid
      assert Repo.aggregate(Transaction, :count) == 3

      # Create tip for different recipient within cooldown period
      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/tip $50 @#{other_user.provider_login}",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      # Second tip should be autopaid since it's for a different recipient
      assert Repo.aggregate(Transaction, :count) == 6
      refute_enqueued(worker: NotifyTipIntent)
    end
  end

  describe "create claims" do
    test "creates claims with split shares", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number} /split @jsmith /split @jdoe",
          params: %{"pull_request" => %{"number" => pr_number}}
        }
      ])

      claims = Repo.all(Claim)

      assert length(claims) == 3
      assert Enum.all?(claims, &(&1.group_share == Decimal.div(1, 3)))
      assert Enum.all?(claims, &(&1.group_id == hd(claims).group_id))
      assert Enum.all?(claims, &(&1.source_id == hd(claims).source_id))
      assert Enum.all?(claims, &(&1.target_id == hd(claims).target_id))
    end

    test "", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        }
      ])

      claims = Repo.all(Claim)
      assert length(claims) == 1
      assert Enum.all?(claims, &(&1.group_share == Decimal.div(1, 1)))

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number} /split @jsmith",
          params: %{"pull_request" => %{"number" => pr_number}}
        }
      ])

      claims = Repo.all(Claim)
      assert length(claims) == 2
      assert Enum.all?(claims, &(&1.group_share == Decimal.div(1, 2)))

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        }
      ])

      claims = Repo.all(from c in Claim, where: c.status == :pending)
      assert length(claims) == 1
      assert Enum.all?(claims, &(&1.group_share == Decimal.div(1, 1)))

      claims = Repo.all(from c in Claim, where: c.status == :cancelled)
      assert length(claims) == 1
      assert Enum.all?(claims, &(&1.group_share == Decimal.div(0, 1)))

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number} /split @jdoe",
          params: %{"pull_request" => %{"number" => pr_number}}
        }
      ])

      claims = Repo.all(from c in Claim, where: c.status == :pending)
      assert length(claims) == 2
      assert Enum.all?(claims, &(&1.group_share == Decimal.div(1, 2)))

      claims = Repo.all(from c in Claim, where: c.status == :cancelled)
      assert length(claims) == 1
    end

    test "claim command is idempotent when editing pull request", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        },
        %{
          event_action: "pull_request.edited",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        }
      ])

      assert Repo.aggregate(Claim, :count) == 1
    end

    test "does not allow multiple claims in a single PR", ctx do
      issue_number1 = :rand.uniform(1000)
      issue_number2 = issue_number1 + 1
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number1}}
        },
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number2}}
        }
      ])

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number1} /claim #{issue_number2}",
          params: %{"pull_request" => %{"number" => pr_number}}
        }
      ])

      assert Repo.aggregate(Claim, :count) == 1
    end

    test "cancels existing claim when attempting to claim a different bounty in the same PR", ctx do
      issue_number1 = :rand.uniform(1000)
      issue_number2 = issue_number1 + 1
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number1}}
        },
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number2}}
        }
      ])

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number1}",
          params: %{"pull_request" => %{"number" => pr_number}}
        }
      ])

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number2}",
          params: %{"pull_request" => %{"number" => pr_number}}
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
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        }
      ])

      assert Repo.aggregate(Claim, :count) == 0

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        }
      ])

      claims = Repo.all(Claim)
      assert length(claims) == 1

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.edited",
          user_type: :unauthorized,
          body: "/claim #{issue_number} /split @jsmith",
          params: %{"pull_request" => %{"number" => pr_number}}
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
          params: %{"pull_request" => %{"number" => pr_number}}
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
          params: %{"pull_request" => %{"number" => pr_number}}
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
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        },
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number, "merged_at" => nil}}
        }
      ])

      assert Repo.one(Claim).status == :pending
    end

    test "does nothing when merged pull request has no claims", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "fixes #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        },
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "fixes #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number, "merged_at" => DateTime.to_iso8601(DateTime.utc_now())}}
        }
      ])

      assert Repo.aggregate(Claim, :count) == 0
    end

    test "approves claim when pull request is merged", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        },
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number, "merged_at" => DateTime.to_iso8601(DateTime.utc_now())}}
        }
      ])

      assert Repo.one(Claim).status == :approved
    end

    test "handles autopay", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      customer = insert!(:customer, user: ctx[:org])
      _payment_method = insert!(:payment_method, is_default: true, customer: customer)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        },
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number, "merged_at" => DateTime.to_iso8601(DateTime.utc_now())}}
        }
      ])

      bounty = Repo.one!(Bounty)
      claim = Repo.one!(Claim)
      assert claim.target_id == bounty.ticket_id
      assert claim.status == :approved

      charge = Repo.one!(from t in Transaction, where: t.type == :charge)
      assert Money.equal?(charge.net_amount, Money.new(:USD, 100))
      assert charge.status == :initialized
      assert charge.user_id == ctx[:org].id

      debit = Repo.one!(from t in Transaction, where: t.type == :debit)
      assert Money.equal?(debit.net_amount, Money.new(:USD, 100))
      assert debit.status == :initialized
      assert debit.user_id == ctx[:org].id
      assert debit.bounty_id == bounty.id
      assert debit.claim_id == claim.id

      credit = Repo.one!(from t in Transaction, where: t.type == :credit)
      assert Money.equal?(credit.net_amount, Money.new(:USD, 100))
      assert credit.status == :initialized
      assert credit.user_id == ctx[:unauthorized_user].id
      assert credit.bounty_id == bounty.id
      assert credit.claim_id == claim.id

      transfer = Repo.one(from t in Transaction, where: t.type == :transfer)
      assert is_nil(transfer)
    end

    test "does not autopay when payment method is not default", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      customer = insert!(:customer, user: ctx[:org])
      _payment_method = insert!(:payment_method, is_default: false, customer: customer)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        },
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number, "merged_at" => DateTime.to_iso8601(DateTime.utc_now())}}
        }
      ])

      bounty = Repo.one!(Bounty)
      claim = Repo.one!(Claim)
      assert claim.target_id == bounty.ticket_id
      assert claim.status == :approved
      assert Repo.aggregate(Transaction, :count) == 0
    end

    test "does not autopay when autopay is disabled", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      customer = insert!(:customer, user: ctx[:org])
      _payment_method = insert!(:payment_method, customer: customer)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        }
      ])

      Bounty |> Repo.one!() |> change(%{autopay_disabled: true}) |> Repo.update!()

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number, "merged_at" => DateTime.to_iso8601(DateTime.utc_now())}}
        }
      ])

      bounty = Repo.one!(Bounty)
      claim = Repo.one!(Claim)
      assert claim.target_id == bounty.ticket_id
      assert claim.status == :approved
      assert Repo.aggregate(Transaction, :count) == 0
    end

    test "handles autopay when claim is changed to a different bounty and PR is merged", ctx do
      issue_number1 = :rand.uniform(1000)
      issue_number2 = issue_number1 + :rand.uniform(1000)
      pr_number = issue_number1 + :rand.uniform(1000)

      customer = insert!(:customer, user: ctx[:org])
      _payment_method = insert!(:payment_method, is_default: true, customer: customer)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number1}}
        },
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $200",
          params: %{"issue" => %{"number" => issue_number2}}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number1}",
          params: %{"pull_request" => %{"number" => pr_number}}
        },
        %{
          event_action: "pull_request.edited",
          user_type: :unauthorized,
          body: "/claim #{issue_number2}",
          params: %{"pull_request" => %{"number" => pr_number}}
        },
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "/claim #{issue_number2}",
          params: %{"pull_request" => %{"number" => pr_number, "merged_at" => DateTime.to_iso8601(DateTime.utc_now())}}
        }
      ])

      ticket1 = Repo.get_by!(Ticket, number: issue_number1)
      ticket2 = Repo.get_by!(Ticket, number: issue_number2)

      _bounty1 = Repo.get_by!(Bounty, ticket_id: ticket1.id)
      bounty2 = Repo.get_by!(Bounty, ticket_id: ticket2.id)

      cancelled_claim = Repo.get_by!(Claim, target_id: ticket1.id)
      active_claim = Repo.get_by!(Claim, target_id: ticket2.id)

      assert active_claim.status == :approved
      assert cancelled_claim.status == :cancelled

      charge = Repo.one!(from t in Transaction, where: t.type == :charge)
      assert Money.equal?(charge.net_amount, Money.new(:USD, 200))
      assert charge.status == :initialized
      assert charge.user_id == ctx[:org].id

      debit = Repo.one!(from t in Transaction, where: t.type == :debit)
      assert Money.equal?(debit.net_amount, Money.new(:USD, 200))
      assert debit.status == :initialized
      assert debit.user_id == ctx[:org].id
      assert debit.bounty_id == bounty2.id
      assert debit.claim_id == active_claim.id

      credit = Repo.one!(from t in Transaction, where: t.type == :credit)
      assert Money.equal?(credit.net_amount, Money.new(:USD, 200))
      assert credit.status == :initialized
      assert credit.user_id == ctx[:unauthorized_user].id
      assert credit.bounty_id == bounty2.id
      assert credit.claim_id == active_claim.id
    end

    test "prevents duplicate transaction creation when receiving multiple PR closed events", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      customer = insert!(:customer, user: ctx[:org])
      _payment_method = insert!(:payment_method, is_default: true, customer: customer)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number}}
        },
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "/claim #{issue_number}",
          params: %{"pull_request" => %{"number" => pr_number, "merged_at" => DateTime.to_iso8601(DateTime.utc_now())}}
        }
      ])

      assert Repo.aggregate(from(t in Transaction, where: t.type == :charge), :count) == 1
      assert Repo.aggregate(from(t in Transaction, where: t.type == :debit), :count) == 1
      assert Repo.aggregate(from(t in Transaction, where: t.type == :credit), :count) == 1

      {:ok, log} =
        with_log(fn ->
          process_scenario(ctx, [
            %{
              event_action: "pull_request.closed",
              user_type: :unauthorized,
              body: "/claim #{issue_number}",
              params: %{
                "pull_request" => %{"number" => pr_number, "merged_at" => DateTime.to_iso8601(DateTime.utc_now())}
              }
            }
          ])
        end)

      assert log =~ "Autopay failed"

      assert Repo.aggregate(from(t in Transaction, where: t.type == :charge), :count) == 1
      assert Repo.aggregate(from(t in Transaction, where: t.type == :debit), :count) == 1
      assert Repo.aggregate(from(t in Transaction, where: t.type == :credit), :count) == 1
    end

    test "handles split bounty payments between two users when PR is merged", ctx do
      issue_number = :rand.uniform(1000)
      pr_number = :rand.uniform(1000)

      customer = insert!(:customer, user: ctx[:org])
      _payment_method = insert!(:payment_method, is_default: true, customer: customer)

      user1 = ctx[:unauthorized_user]
      user2 = insert!(:user)

      process_scenario!(ctx, [
        %{
          event_action: "issue_comment.created",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number}}
        },
        %{
          event_action: "pull_request.opened",
          user_type: :unauthorized,
          body: "/claim #{issue_number} /split @#{user2.provider_login}",
          params: %{"pull_request" => %{"number" => pr_number}}
        },
        %{
          event_action: "pull_request.closed",
          user_type: :unauthorized,
          body: "/claim #{issue_number} /split @#{user2.provider_login}",
          params: %{"pull_request" => %{"number" => pr_number, "merged_at" => DateTime.to_iso8601(DateTime.utc_now())}}
        }
      ])

      bounty = Repo.one!(Bounty)
      claim1 = Repo.one!(from c in Claim, where: c.user_id == ^user1.id)
      claim2 = Repo.one!(from c in Claim, where: c.user_id == ^user2.id)
      assert claim1.target_id == bounty.ticket_id
      assert claim1.status == :approved
      assert claim2.status == :approved

      charge = Repo.one!(from t in Transaction, where: t.type == :charge)
      assert Money.equal?(charge.net_amount, Money.new(:USD, 100))
      assert charge.status == :initialized
      assert charge.user_id == ctx[:org].id

      debit1 = Repo.one!(from t in Transaction, where: t.type == :debit and t.claim_id == ^claim1.id)
      assert Money.equal?(debit1.net_amount, Money.new(:USD, 50))
      assert debit1.status == :initialized
      assert debit1.user_id == ctx[:org].id
      assert debit1.bounty_id == bounty.id

      debit2 = Repo.one!(from t in Transaction, where: t.type == :debit and t.claim_id == ^claim2.id)
      assert Money.equal?(debit2.net_amount, Money.new(:USD, 50))
      assert debit2.status == :initialized
      assert debit2.user_id == ctx[:org].id
      assert debit2.bounty_id == bounty.id

      credit1 = Repo.one!(from t in Transaction, where: t.type == :credit and t.claim_id == ^claim1.id)
      assert Money.equal?(credit1.net_amount, Money.new(:USD, 50))
      assert credit1.status == :initialized
      assert credit1.user_id == user1.id
      assert credit1.bounty_id == bounty.id

      credit2 = Repo.one!(from t in Transaction, where: t.type == :credit and t.claim_id == ^claim2.id)
      assert Money.equal?(credit2.net_amount, Money.new(:USD, 50))
      assert credit2.status == :initialized
      assert credit2.user_id == user2.id
      assert credit2.bounty_id == bounty.id

      transfer = Repo.one(from t in Transaction, where: t.type == :transfer)
      assert is_nil(transfer)
    end
  end

  describe "ticket state updates" do
    test "updates ticket state on issues.opened", ctx do
      issue_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "issues.opened",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number, "state" => "open"}}
        }
      ])

      ticket = Repo.get_by!(Ticket, number: issue_number)
      assert ticket.state == :open
      assert ticket.closed_at == nil
      assert ticket.merged_at == nil
    end

    test "updates ticket state on issues.closed", ctx do
      issue_number = :rand.uniform(1000)
      closed_at = DateTime.utc_now()

      process_scenario!(ctx, [
        %{
          event_action: "issues.opened",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number, "state" => "open"}}
        },
        %{
          event_action: "issues.closed",
          user_type: :repo_admin,
          params: %{
            "issue" => %{
              "number" => issue_number,
              "state" => "closed",
              "closed_at" => DateTime.to_iso8601(closed_at)
            }
          }
        }
      ])

      ticket = Repo.get_by!(Ticket, number: issue_number)
      assert ticket.state == :closed
      assert DateTime.compare(ticket.closed_at, closed_at) == :eq
      assert ticket.merged_at == nil
    end

    test "updates ticket state on issues.reopened", ctx do
      issue_number = :rand.uniform(1000)
      closed_at = DateTime.utc_now()

      process_scenario!(ctx, [
        %{
          event_action: "issues.opened",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{"issue" => %{"number" => issue_number, "state" => "open"}}
        },
        %{
          event_action: "issues.closed",
          user_type: :repo_admin,
          params: %{
            "issue" => %{
              "number" => issue_number,
              "state" => "closed",
              "closed_at" => DateTime.to_iso8601(closed_at)
            }
          }
        },
        %{
          event_action: "issues.reopened",
          user_type: :repo_admin,
          params: %{
            "issue" => %{
              "number" => issue_number,
              "state" => "open",
              "closed_at" => nil
            }
          }
        }
      ])

      ticket = Repo.get_by!(Ticket, number: issue_number)
      assert ticket.state == :open
      assert ticket.closed_at == nil
      assert ticket.merged_at == nil
    end

    test "updates ticket state on pull_request.opened", ctx do
      pr_number = :rand.uniform(1000)

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{
            "pull_request" => %{
              "number" => pr_number,
              "state" => "open"
            }
          }
        }
      ])

      ticket = Repo.get_by!(Ticket, number: pr_number)
      assert ticket.state == :open
      assert ticket.closed_at == nil
      assert ticket.merged_at == nil
    end

    test "updates ticket state on pull_request.closed without merge", ctx do
      pr_number = :rand.uniform(1000)
      closed_at = DateTime.utc_now()

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{
            "pull_request" => %{
              "number" => pr_number,
              "state" => "open"
            }
          }
        },
        %{
          event_action: "pull_request.closed",
          user_type: :repo_admin,
          params: %{
            "pull_request" => %{
              "number" => pr_number,
              "state" => "closed",
              "closed_at" => DateTime.to_iso8601(closed_at),
              "merged_at" => nil
            }
          }
        }
      ])

      ticket = Repo.get_by!(Ticket, number: pr_number)
      assert ticket.state == :closed
      assert DateTime.compare(ticket.closed_at, closed_at) == :eq
      assert ticket.merged_at == nil
    end

    test "updates ticket state on pull_request.closed with merge", ctx do
      pr_number = :rand.uniform(1000)
      closed_at = DateTime.utc_now()
      merged_at = DateTime.add(closed_at, -1, :second)

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{
            "pull_request" => %{
              "number" => pr_number,
              "state" => "open"
            }
          }
        },
        %{
          event_action: "pull_request.closed",
          user_type: :repo_admin,
          params: %{
            "pull_request" => %{
              "number" => pr_number,
              "state" => "closed",
              "closed_at" => DateTime.to_iso8601(closed_at),
              "merged_at" => DateTime.to_iso8601(merged_at)
            }
          }
        }
      ])

      ticket = Repo.get_by!(Ticket, number: pr_number)
      assert ticket.state == :closed
      assert DateTime.compare(ticket.closed_at, closed_at) == :eq
      assert DateTime.compare(ticket.merged_at, merged_at) == :eq
    end

    test "updates ticket state on pull_request.reopened", ctx do
      pr_number = :rand.uniform(1000)
      closed_at = DateTime.utc_now()

      process_scenario!(ctx, [
        %{
          event_action: "pull_request.opened",
          user_type: :repo_admin,
          body: "/bounty $100",
          params: %{
            "pull_request" => %{
              "number" => pr_number,
              "state" => "open"
            }
          }
        },
        %{
          event_action: "pull_request.closed",
          user_type: :repo_admin,
          params: %{
            "pull_request" => %{
              "number" => pr_number,
              "state" => "closed",
              "closed_at" => DateTime.to_iso8601(closed_at),
              "merged_at" => nil
            }
          }
        },
        %{
          event_action: "pull_request.reopened",
          user_type: :repo_admin,
          params: %{
            "pull_request" => %{
              "number" => pr_number,
              "state" => "open",
              "closed_at" => nil,
              "merged_at" => nil
            }
          }
        }
      ])

      ticket = Repo.get_by!(Ticket, number: pr_number)
      assert ticket.state == :open
      assert ticket.closed_at == nil
      assert ticket.merged_at == nil
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
        :org_admin -> ctx[:org_admin]
        :org_mod -> ctx[:org_mod]
        :org_expert -> ctx[:org_expert]
        :repo_admin -> ctx[:repo_admin]
      end

    [event, action] = String.split(ctx[:event_action], ".")

    ctx = Map.merge(ctx, %{event: event, action: action, author: author, params: ctx[:params] || %{}})

    %Webhook{
      event: event,
      event_action: "#{event}.#{action}",
      hook_id: "123456789",
      delivery: Ecto.UUID.generate(),
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

  defp merge_payload(base_payload, params) do
    Map.new(base_payload, fn {key, base_value} ->
      case {base_value, get_in(params || %{}, [key])} do
        {base_map, override_map} when is_map(base_map) and is_map(override_map) ->
          {key, Map.merge(base_map, override_map)}

        _ ->
          {key, base_value}
      end
    end)
  end

  defp mock_payload(%{event: "issue_comment"} = ctx) do
    ctx
    |> mock_base_payload()
    |> Map.merge(
      merge_payload(
        %{
          "comment" => %{
            "id" => 123,
            "body" => mock_body(ctx[:body]),
            "user" => mock_user(ctx[:author])
          },
          "issue" => %{
            "id" => 123,
            "number" => 123,
            "state" => "open",
            "body" => mock_body(),
            "user" => mock_user(ctx[:repo_admin])
          }
        },
        ctx[:params]
      )
    )
  end

  defp mock_payload(%{event: "issues"} = ctx) do
    ctx
    |> mock_base_payload()
    |> Map.merge(
      merge_payload(
        %{
          "issue" => %{
            "id" => 123,
            "number" => 123,
            "state" => "open",
            "title" => "Default Issue Title",
            "body" => mock_body(ctx[:body]),
            "user" => mock_user(ctx[:author])
          }
        },
        ctx[:params]
      )
    )
  end

  defp mock_payload(%{event: "pull_request"} = ctx) do
    ctx
    |> mock_base_payload()
    |> Map.merge(
      merge_payload(
        %{
          "pull_request" => %{
            "id" => 123,
            "number" => 123,
            "state" => "open",
            "title" => "Default PR Title",
            "body" => mock_body(ctx[:body]),
            "user" => mock_user(ctx[:author]),
            "merged_at" => nil
          }
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
