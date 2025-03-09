defmodule Algora.BountiesTest do
  use Algora.DataCase
  use Oban.Testing, repo: Algora.Repo

  import Algora.Factory
  import Money.Sigil

  alias Algora.Accounts.User
  alias Algora.Activities.Notifier
  alias Algora.Activities.SendEmail
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Payments.Transaction
  alias Algora.PSP
  alias Bounties.Tip

  setup do
    creator = insert!(:user)
    owner = insert!(:user, bounty_mode: :community)
    _installation = insert!(:installation, owner: creator, connected_user: owner)
    _identity = insert!(:identity, user: creator, provider_email: creator.email)
    repo = insert!(:repository, %{user: owner})
    ticket = insert!(:ticket, %{repository: repo})
    ticket_ref = %{owner: owner.handle, repo: repo.name, number: ticket.number}

    %{creator: creator, owner: owner, repo: repo, ticket: ticket, ticket_ref: ticket_ref}
  end

  describe "bounties" do
    test "create" do
      creator = insert!(:user)
      owner = insert!(:user)
      recipient = insert!(:user)
      installation = insert!(:installation, owner: creator, connected_user: owner)
      _identity = insert!(:identity, user: creator, provider_email: creator.email)
      repo = insert!(:repository, %{user: owner})
      ticket = insert!(:ticket, %{repository: repo})
      amount = ~M[4000]usd

      ticket_ref = %{
        owner: owner.handle,
        repo: repo.name,
        number: ticket.number
      }

      bounty_params =
        %{
          ticket_ref: ticket_ref,
          owner: owner,
          creator: creator,
          amount: amount
        }

      assert {:ok, bounty} = Bounties.create_bounty(bounty_params, [])

      assert bounty.visibility == :public

      assert {:ok, claims} =
               Bounties.claim_bounty(
                 %{
                   user: recipient,
                   coauthor_provider_logins: [],
                   target_ticket_ref: ticket_ref,
                   source_ticket_ref: ticket_ref,
                   status: :approved,
                   type: :pull_request
                 },
                 installation_id: installation.id
               )

      claims = Repo.preload(claims, :user)

      assert {:ok, _bounty} =
               Bounties.reward_bounty(
                 %{
                   owner: owner,
                   amount: ~M[4000]usd,
                   bounty_id: bounty.id,
                   claims: claims
                 },
                 installation_id: installation.id
               )

      assert {:ok, _stripe_session_url} =
               Bounties.create_tip(
                 %{
                   amount: amount,
                   owner: owner,
                   creator: creator,
                   recipient: recipient
                 },
                 ticket_ref: ticket_ref,
                 claims: claims
               )

      assert_activity_names([:bounty_posted, :claim_submitted, :bounty_awarded, :tip_awarded])
      assert_activity_names_for_user(creator.id, [:bounty_posted, :bounty_awarded, :tip_awarded])
      assert_activity_names_for_user(recipient.id, [:claim_submitted, :tip_awarded])

      assert [bounty, _claim, _awarded, tip] = Enum.reverse(Algora.Activities.all())
      assert "tip_activities" == tip.assoc_name
      # assert tip.notify_users == [recipient.id]
      assert activity = Algora.Activities.get_with_preloaded_assoc(tip.assoc_name, tip.id)
      assert activity.assoc.__meta__.schema == Tip
      assert activity.assoc.creator.id == creator.id

      assert_enqueued(worker: Notifier, args: %{"activity_id" => bounty.id})
      refute_enqueued(worker: SendEmail, args: %{"activity_id" => bounty.id})

      Enum.map(all_enqueued(worker: Notifier), fn job ->
        perform_job(Notifier, job.args)
      end)

      # assert_enqueued(worker: SendEmail, args: %{"activity_id" => bounty.id})
    end

    test "create public bounty", %{owner: owner, creator: creator, ticket_ref: ticket_ref} do
      {:ok, bounty} =
        Bounties.create_bounty(%{
          ticket_ref: ticket_ref,
          owner: owner |> change(%{bounty_mode: :public}) |> Repo.update!(),
          creator: creator,
          amount: ~M[100]usd
        })

      assert bounty.visibility == :public
    end

    test "create community bounty", %{owner: owner, creator: creator, ticket_ref: ticket_ref} do
      {:ok, bounty} =
        Bounties.create_bounty(%{
          ticket_ref: ticket_ref,
          owner: owner |> change(%{bounty_mode: :community}) |> Repo.update!(),
          creator: creator,
          amount: ~M[100]usd
        })

      assert bounty.visibility == :community
    end

    test "create exclusive bounty", %{owner: owner, creator: creator, ticket_ref: ticket_ref} do
      {:ok, bounty} =
        Bounties.create_bounty(%{
          ticket_ref: ticket_ref,
          owner: owner |> change(%{bounty_mode: :exclusive}) |> Repo.update!(),
          creator: creator,
          amount: ~M[100]usd
        })

      assert bounty.visibility == :exclusive
    end

    test "successfully creates and pays invoice for bounty claim" do
      creator = insert!(:user)
      owner = insert!(:organization)
      customer = insert!(:customer, user: owner)
      payment_method = insert!(:payment_method, customer: customer)
      recipient = insert!(:user)
      installation = insert!(:installation, owner: creator, connected_user: owner)
      _identity = insert!(:identity, user: creator, provider_email: creator.email)
      repo = insert!(:repository, %{user: owner})
      ticket = insert!(:ticket, %{repository: repo})
      amount = ~M[4000]usd

      ticket_ref = %{
        owner: owner.handle,
        repo: repo.name,
        number: ticket.number
      }

      assert {:ok, bounty} =
               Bounties.create_bounty(
                 %{
                   ticket_ref: ticket_ref,
                   owner: owner,
                   creator: creator,
                   amount: amount
                 },
                 installation_id: installation.id
               )

      assert {:ok, [claim]} =
               Bounties.claim_bounty(
                 %{
                   user: recipient,
                   coauthor_provider_logins: [],
                   target_ticket_ref: ticket_ref,
                   source_ticket_ref: ticket_ref,
                   status: :pending,
                   type: :pull_request
                 },
                 installation_id: installation.id
               )

      claim = Repo.preload(claim, :user)

      assert {:ok, invoice} =
               Bounties.create_invoice(
                 %{owner: owner, amount: amount, idempotency_key: "bounty-#{bounty.id}"},
                 ticket_ref: ticket_ref,
                 bounty_id: bounty.id,
                 claims: [claim]
               )

      assert {:ok, _invoice} =
               PSP.Invoice.pay(
                 invoice,
                 %{
                   payment_method: payment_method.provider_id,
                   off_session: true
                 },
                 %{idempotency_key: "bounty-#{bounty.id}"}
               )

      charge = Repo.one!(from t in Transaction, where: t.type == :charge)
      assert Money.equal?(charge.net_amount, amount)
      assert charge.status == :initialized
      assert charge.user_id == owner.id

      debit = Repo.one!(from t in Transaction, where: t.type == :debit)
      assert Money.equal?(debit.net_amount, amount)
      assert debit.status == :initialized
      assert debit.user_id == owner.id
      assert debit.bounty_id == bounty.id
      assert debit.claim_id == claim.id

      credit = Repo.one!(from t in Transaction, where: t.type == :credit)
      assert Money.equal?(credit.net_amount, amount)
      assert credit.status == :initialized
      assert credit.user_id == recipient.id
      assert credit.bounty_id == bounty.id
      assert credit.claim_id == claim.id

      transfer = Repo.one(from t in Transaction, where: t.type == :transfer)
      assert is_nil(transfer)
    end
  end

  describe "tips" do
    test "successfully creates checkout url for tips" do
      creator = insert!(:user)
      owner = insert!(:organization)
      recipient = insert!(:user)
      _installation = insert!(:installation, owner: creator, connected_user: owner)
      _identity = insert!(:identity, user: creator, provider_email: creator.email)
      repo = insert!(:repository, %{user: owner})
      ticket = insert!(:ticket, %{repository: repo})
      amount = ~M[4000]usd

      ticket_ref = %{
        owner: owner.handle,
        repo: repo.name,
        number: ticket.number
      }

      assert {:ok, _checkout_url} =
               Bounties.create_tip(
                 %{
                   amount: amount,
                   owner: owner,
                   creator: creator,
                   recipient: recipient
                 },
                 ticket_ref: ticket_ref
               )

      tip = Repo.one!(Tip)

      charge = Repo.one!(from t in Transaction, where: t.type == :charge)
      assert Money.equal?(charge.net_amount, amount)
      assert charge.status == :initialized
      assert charge.user_id == owner.id

      debit = Repo.one!(from t in Transaction, where: t.type == :debit)
      assert Money.equal?(debit.net_amount, amount)
      assert debit.status == :initialized
      assert debit.user_id == owner.id
      assert debit.tip_id == tip.id

      credit = Repo.one!(from t in Transaction, where: t.type == :credit)
      assert Money.equal?(credit.net_amount, amount)
      assert credit.status == :initialized
      assert credit.user_id == recipient.id
      assert credit.tip_id == tip.id

      transfer = Repo.one(from t in Transaction, where: t.type == :transfer)
      assert is_nil(transfer)
    end
  end

  describe "PrizePool.list/1" do
    test "solver only sees bounties from orgs they received payments from" do
      solver = insert!(:user)
      org_with_history = insert!(:user)
      org_without_history = insert!(:user)

      credit_id = Nanoid.generate()
      debit_id = Nanoid.generate()

      insert!(:transaction, %{
        id: credit_id,
        type: :credit,
        user_id: solver.id,
        net_amount: ~M[100]usd,
        status: :succeeded,
        linked_transaction_id: debit_id
      })

      insert!(:transaction, %{
        id: debit_id,
        type: :debit,
        user_id: org_with_history.id,
        net_amount: ~M[100]usd,
        status: :succeeded,
        linked_transaction_id: credit_id
      })

      for org <- [org_with_history, org_without_history] do
        for _ <- 1..5 do
          creator = insert!(:user)
          repo = insert!(:repository, user: org)
          _installation = insert!(:installation, owner: creator, connected_user: org)
          _identity = insert!(:identity, user: creator, provider_email: creator.email)
          ticket = insert!(:ticket, repository: repo)

          bounty_params = %{
            ticket_ref: %{owner: org.provider_login, repo: repo.name, number: ticket.number},
            owner: org,
            creator: creator,
            amount: ~M[100]usd
          }

          Bounties.create_bounty(bounty_params, [])
        end
      end

      result = Bounties.PrizePool.list(viewer_id: solver.id)

      assert length(result) == 5
      assert Enum.all?(result, fn pool -> pool.repository.owner.id == org_with_history.id end)
    end
  end

  describe "get_response_body/4" do
    test "generates correct response body with bounties and attempts" do
      repo_owner = insert!(:user, provider_login: "repo_owner")
      bounty_owner = insert!(:user, handle: "bounty_owner", display_name: "Bounty Owner")
      bounty_owner = Repo.get!(User, bounty_owner.id)
      repository = insert!(:repository, user: repo_owner, name: "test_repo")

      bounties = [
        %Bounty{
          amount: Money.new(1000, :USD),
          owner: bounty_owner
        }
      ]

      ticket = insert!(:ticket, number: 100, repository: repository)

      ticket_ref = %{
        owner: repo_owner.provider_login,
        repo: ticket.repository.name,
        number: ticket.number
      }

      solver1 = insert!(:user, provider_login: "solver1")
      solver2 = insert!(:user, provider_login: "solver2")
      solver3 = insert!(:user, provider_login: "solver3")
      solver4 = insert!(:user, provider_login: "solver4")
      solver5 = insert!(:user, provider_login: "solver5")
      solver6 = insert!(:user, provider_login: "solver6")

      attempts = [
        insert!(:attempt,
          user: solver1,
          ticket: ticket,
          status: :active,
          warnings_count: 0,
          inserted_at: ~U[2024-01-01 12:00:00Z]
        ),
        insert!(:attempt,
          user: solver3,
          ticket: ticket,
          status: :inactive,
          warnings_count: 0,
          inserted_at: ~U[2024-01-03 12:00:00Z]
        ),
        insert!(:attempt,
          user: solver4,
          ticket: ticket,
          status: :active,
          warnings_count: 1,
          inserted_at: ~U[2024-01-04 12:00:00Z]
        ),
        insert!(:attempt,
          user: solver5,
          ticket: ticket,
          status: :active,
          warnings_count: 0,
          inserted_at: ~U[2024-01-05 12:00:00Z]
        )
      ]

      claims = [
        insert!(:claim,
          user: solver1,
          target: ticket,
          source: insert!(:ticket, number: 101, repository: repository),
          inserted_at: ~U[2024-01-01 12:30:00Z],
          group_id: "group-101"
        ),
        insert!(:claim,
          user: solver2,
          target: ticket,
          source: insert!(:ticket, number: 102, repository: repository),
          inserted_at: ~U[2024-01-02 12:30:00Z],
          group_id: "group-102"
        ),
        insert!(:claim,
          user: solver5,
          target: ticket,
          source: insert!(:ticket, number: 105, repository: repository),
          inserted_at: ~U[2024-01-05 12:30:00Z],
          group_id: "group-105"
        ),
        insert!(:claim,
          user: solver6,
          target: ticket,
          source: insert!(:ticket, number: 105, repository: repository),
          inserted_at: ~U[2024-01-05 12:30:00Z],
          group_id: "group-105"
        )
      ]

      response = Algora.Bounties.get_response_body(bounties, ticket_ref, attempts, claims)

      expected_response = """
      ## 💎 $1,000.00 bounty [• Bounty Owner](http://localhost:4002/@/bounty_owner)
      ### Steps to solve:
      1. **Start working**: Comment `/attempt #100` with your implementation plan
      2. **Submit work**: Create a pull request including `/claim #100` in the PR body to claim the bounty
      3. **Receive payment**: 100% of the bounty is received 2-5 days post-reward. [Make sure you are eligible for payouts](https://docs.algora.io/bounties/payments#supported-countries-regions)

      Thank you for contributing to repo_owner/test_repo!

      | Attempt | Started (UTC) | Solution | Actions |
      | --- | --- | --- | --- |
      | 🟢 @solver1 | Jan 01, 2024, 12:00:00 PM | #101 | [Reward](http://localhost:4002/claims/group-101) |
      | 🟢 @solver2 | Jan 02, 2024, 12:30:00 PM | #102 | [Reward](http://localhost:4002/claims/group-102) |
      | 🔴 @solver3 | Jan 03, 2024, 12:00:00 PM | WIP |  |
      | 🟡 @solver4 | Jan 04, 2024, 12:00:00 PM | WIP |  |
      | 🟢 @solver5 and @solver6 | Jan 05, 2024, 12:00:00 PM | #105 | [Reward](http://localhost:4002/claims/group-105) |
      """

      assert response == String.trim(expected_response)
    end

    test "generates response body without attempts table when no attempts exist" do
      repo_owner = insert!(:user, provider_login: "repo_owner")
      bounty_owner = insert!(:user, handle: "bounty_owner", display_name: "Bounty Owner")
      bounty_owner = Repo.get!(User, bounty_owner.id)
      repository = insert!(:repository, user: repo_owner, name: "test_repo")

      bounties = [
        %Bounty{
          amount: Money.new(1000, :USD),
          owner: bounty_owner
        }
      ]

      ticket = insert!(:ticket, number: 100, repository: repository)

      ticket_ref = %{
        owner: repo_owner.provider_login,
        repo: ticket.repository.name,
        number: ticket.number
      }

      response = Algora.Bounties.get_response_body(bounties, ticket_ref, [], [])

      expected_response = """
      ## 💎 $1,000.00 bounty [• Bounty Owner](http://localhost:4002/@/bounty_owner)
      ### Steps to solve:
      1. **Start working**: Comment `/attempt #100` with your implementation plan
      2. **Submit work**: Create a pull request including `/claim #100` in the PR body to claim the bounty
      3. **Receive payment**: 100% of the bounty is received 2-5 days post-reward. [Make sure you are eligible for payouts](https://docs.algora.io/bounties/payments#supported-countries-regions)

      Thank you for contributing to repo_owner/test_repo!
      """

      assert response == String.trim(expected_response)
    end
  end

  describe "list_bounties/1" do
    test "does not include cancelled bounties", %{ticket: ticket} do
      insert!(:bounty, status: :open, ticket: ticket, owner: insert!(:user))
      insert!(:bounty, status: :paid, ticket: ticket, owner: insert!(:user))
      insert!(:bounty, status: :cancelled, ticket: ticket, owner: insert!(:user))

      bounties = Bounties.list_bounties()
      assert Enum.any?(bounties, &(&1.status == :open))
      assert Enum.any?(bounties, &(&1.status == :paid))
      refute Enum.any?(bounties, &(&1.status == :cancelled))
    end
  end

  describe "list_claims/1" do
    test "does not include cancelled claims", %{ticket: ticket} do
      insert!(:claim, status: :pending, target: ticket, user: insert!(:user))
      insert!(:claim, status: :approved, target: ticket, user: insert!(:user))
      insert!(:claim, status: :cancelled, target: ticket, user: insert!(:user))

      claims = Bounties.list_claims([ticket.id])
      assert Enum.any?(claims, &(&1.status == :pending))
      assert Enum.any?(claims, &(&1.status == :approved))
      refute Enum.any?(claims, &(&1.status == :cancelled))
    end
  end
end
