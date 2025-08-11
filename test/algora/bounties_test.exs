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

      assert bounty.visibility == :community

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
                   bounty: bounty,
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

      assert_activity_names([:bounty_posted, :claim_submitted])
      assert_activity_names_for_user(creator.id, [:bounty_posted])
      assert_activity_names_for_user(recipient.id, [:claim_submitted])

      assert [bounty, _claim] = Enum.reverse(Algora.Activities.all())

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
                 bounty: bounty,
                 claims: [claim]
               )

      assert {:ok, _invoice} = PSP.Invoice.pay(invoice, %{payment_method: payment_method.provider_id, off_session: true})

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

    test "preserves visibility when editing bounty comment", %{owner: owner, creator: creator, ticket_ref: ticket_ref} do
      # Create initial bounty with explicit visibility
      {:ok, bounty} =
        Bounties.create_bounty(%{
          ticket_ref: ticket_ref,
          owner: owner |> change(%{bounty_mode: :public}) |> Repo.update!(),
          creator: creator,
          amount: ~M[100]usd,
          visibility: :public
        })

      assert bounty.visibility == :public

      # Simulate editing the bounty comment (like GitHub webhook would do)
      # This should preserve the existing visibility, not set it to nil
      {:ok, updated_bounty} =
        Bounties.create_bounty(
          %{
            ticket_ref: ticket_ref,
            owner: owner,
            creator: creator,
            amount: ~M[200]usd
          },
          strategy: :set
        )

      assert updated_bounty.visibility == :public
    end

    test "preserves visibility when increasing bounty amount", %{owner: owner, creator: creator, ticket_ref: ticket_ref} do
      # Create initial bounty with community visibility
      {:ok, bounty} =
        Bounties.create_bounty(%{
          ticket_ref: ticket_ref,
          owner: owner |> change(%{bounty_mode: :community}) |> Repo.update!(),
          creator: creator,
          amount: ~M[100]usd,
          visibility: :community
        })

      assert bounty.visibility == :community

      # Simulate adding to bounty amount (like GitHub webhook would do)
      {:ok, updated_bounty} =
        Bounties.create_bounty(
          %{
            ticket_ref: ticket_ref,
            owner: owner,
            creator: creator,
            amount: ~M[50]usd
          },
          strategy: :increase
        )

      assert updated_bounty.visibility == :community
    end

    test "preserves exclusive visibility when updating bounty", %{owner: owner, creator: creator, ticket_ref: ticket_ref} do
      # Create initial bounty with exclusive visibility
      {:ok, bounty} =
        Bounties.create_bounty(%{
          ticket_ref: ticket_ref,
          owner: owner |> change(%{bounty_mode: :exclusive}) |> Repo.update!(),
          creator: creator,
          amount: ~M[500]usd,
          visibility: :exclusive
        })

      assert bounty.visibility == :exclusive

      # Simulate webhook edit without visibility parameter
      {:ok, updated_bounty} =
        Bounties.create_bounty(
          %{
            ticket_ref: ticket_ref,
            owner: owner,
            creator: creator,
            amount: ~M[750]usd
          },
          strategy: :set
        )

      assert updated_bounty.visibility == :exclusive
    end

    test "handles nil visibility options without overriding existing value", %{
      owner: owner,
      creator: creator,
      ticket_ref: ticket_ref
    } do
      # Create initial bounty
      {:ok, bounty} =
        Bounties.create_bounty(%{
          ticket_ref: ticket_ref,
          owner: owner |> change(%{bounty_mode: :public}) |> Repo.update!(),
          creator: creator,
          amount: ~M[100]usd
        })

      original_visibility = bounty.visibility

      # Simulate what happens when GitHub webhook doesn't pass visibility option
      {:ok, updated_bounty} =
        Bounties.create_bounty(
          %{
            ticket_ref: ticket_ref,
            owner: owner,
            creator: creator,
            amount: ~M[200]usd
          },
          # Empty options - no visibility passed
          []
        )

      assert updated_bounty.visibility == original_visibility
    end

    test "allows explicit visibility override when provided", %{owner: owner, creator: creator, ticket_ref: ticket_ref} do
      # Create initial bounty with public visibility
      {:ok, bounty} =
        Bounties.create_bounty(%{
          ticket_ref: ticket_ref,
          owner: owner |> change(%{bounty_mode: :public}) |> Repo.update!(),
          creator: creator,
          amount: ~M[100]usd,
          visibility: :public
        })

      assert bounty.visibility == :public

      # Explicitly change visibility to community
      {:ok, updated_bounty} =
        Bounties.create_bounty(
          %{
            ticket_ref: ticket_ref,
            owner: owner,
            creator: creator,
            amount: ~M[200]usd
          },
          strategy: :set,
          visibility: :community
        )

      assert updated_bounty.visibility == :community
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

  describe "get_response_body/4" do
    test "uses custom template when available" do
      repo_owner = insert!(:user, provider_login: "repo_owner")
      bounty_owner = insert!(:user, handle: "bounty_owner", display_name: "Bounty Owner")
      repository = insert!(:repository, user: repo_owner, name: "test_repo")
      ticket = insert!(:ticket, number: 100, repository: repository)

      _custom_template =
        insert!(:bot_template, %{
          user: repo_owner,
          type: :bounty_created,
          template: """
          ${PRIZE_POOL}

          ### Steps to solve:
          1. **Start working**: Comment `/attempt #${ISSUE_NUMBER}` with your implementation plan
          2. **Submit work**: Create a pull request including `/claim #${ISSUE_NUMBER}` in the PR body to claim the bounty
          3. **Receive payment**: 100% of the bounty is received 2-5 days post-reward. [Make sure you are eligible for payouts](https://algora.io/docs/payments#supported-countries-regions)

          ### ❗ Important guidelines:
          - To claim a bounty, you need to **provide a short demo video** of your changes in your pull request
          - If anything is unclear, **ask for clarification** before starting as this will help avoid potential rework
          - For assistance or questions, **[join our Discord](https://algora.io/discord)**

          Thank you for contributing to ${REPO_FULL_NAME}!

          **[Add a bounty](${FUND_URL})** • **[Share on socials](${TWEET_URL})**

          ${ATTEMPTS}
          """
        })

      bounties = [insert!(:bounty, amount: Money.new(1000, :USD), owner: bounty_owner, ticket: ticket)]

      ticket_ref = %{
        owner: repo_owner.provider_login,
        repo: ticket.repository.name,
        number: ticket.number
      }

      response = Bounties.get_response_body(bounties, ticket_ref, [], [])

      expected_response = """
      ## 💎 $1,000 bounty [• Bounty Owner](http://localhost:4002/bounty_owner)

      ### Steps to solve:
      1. **Start working**: Comment `/attempt #100` with your implementation plan
      2. **Submit work**: Create a pull request including `/claim #100` in the PR body to claim the bounty
      3. **Receive payment**: 100% of the bounty is received 2-5 days post-reward. [Make sure you are eligible for payouts](https://algora.io/docs/payments#supported-countries-regions)

      ### ❗ Important guidelines:
      - To claim a bounty, you need to **provide a short demo video** of your changes in your pull request
      - If anything is unclear, **ask for clarification** before starting as this will help avoid potential rework
      - For assistance or questions, **[join our Discord](https://algora.io/discord)**

      Thank you for contributing to repo_owner/test_repo!

      **[Add a bounty](http://localhost:4002)** • **[Share on socials](https://twitter.com/intent/tweet?related=algoraio&text=%241%2C000+bounty%21+%F0%9F%92%8E+https%3A%2F%2Fgithub.com%2Frepo_owner%2Ftest_repo%2Fissues%2F100)**
      """

      assert response == String.trim(expected_response)
    end

    test "uses default template when no custom template exists" do
      repo_owner = insert!(:user, provider_login: "repo_owner")
      bounty_owner = insert!(:user, handle: "bounty_owner", display_name: "Bounty Owner")
      bounty_owner = Repo.get!(User, bounty_owner.id)
      repository = insert!(:repository, user: repo_owner, name: "test_repo")
      ticket = insert!(:ticket, number: 100, repository: repository)

      bounties = [insert!(:bounty, amount: Money.new(1000, :USD), owner: bounty_owner, ticket: ticket)]

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

      response = Bounties.get_response_body(bounties, ticket_ref, attempts, claims)

      expected_response = """
      ## 💎 $1,000 bounty [• Bounty Owner](http://localhost:4002/bounty_owner)
      ### Steps to solve:
      1. **Start working**: Comment `/attempt #100` with your implementation plan
      2. **Submit work**: Create a pull request including `/claim #100` in the PR body to claim the bounty
      3. **Receive payment**: 100% of the bounty is received 2-5 days post-reward. [Make sure you are eligible for payouts](https://algora.io/docs/payments#supported-countries-regions)

      ### ❗ Important guidelines:
      - To claim a bounty, you need to **provide a short demo video** of your changes in your pull request
      - If anything is unclear, **ask for clarification** before starting as this will help avoid potential rework
      - Low quality AI PRs will not receive review and will be closed
      - Do not ask to be assigned unless you've contributed before

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

    test "uses default template when custom template is inactive" do
      repo_owner = insert!(:user, provider_login: "repo_owner")
      bounty_owner = insert!(:user, handle: "bounty_owner", display_name: "Bounty Owner")
      repository = insert!(:repository, user: repo_owner, name: "test_repo")
      ticket = insert!(:ticket, number: 100, repository: repository)

      _custom_template =
        insert!(:bot_template, %{
          user: repo_owner,
          type: :bounty_created,
          active: false,
          template: """
          # Custom Template
          Prize: ${PRIZE_POOL}
          """
        })

      bounties = [
        %Bounty{
          amount: Money.new(1000, :USD),
          owner: bounty_owner,
          ticket_id: ticket.id
        }
      ]

      ticket_ref = %{
        owner: repo_owner.provider_login,
        repo: ticket.repository.name,
        number: ticket.number
      }

      response = Bounties.get_response_body(bounties, ticket_ref, [], [])

      expected_response = """
      ## 💎 $1,000 bounty [• Bounty Owner](http://localhost:4002/bounty_owner)
      ### Steps to solve:
      1. **Start working**: Comment `/attempt #100` with your implementation plan
      2. **Submit work**: Create a pull request including `/claim #100` in the PR body to claim the bounty
      3. **Receive payment**: 100% of the bounty is received 2-5 days post-reward. [Make sure you are eligible for payouts](https://algora.io/docs/payments#supported-countries-regions)

      ### ❗ Important guidelines:
      - To claim a bounty, you need to **provide a short demo video** of your changes in your pull request
      - If anything is unclear, **ask for clarification** before starting as this will help avoid potential rework
      - Low quality AI PRs will not receive review and will be closed
      - Do not ask to be assigned unless you've contributed before

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

  describe "generate_line_items/2" do
    test "uses owner's fee percentage for platform fee" do
      owner = insert!(:user, fee_pct: 5)
      recipient = insert!(:user, provider_login: "recipient")
      amount = Money.new(10_000, :USD)

      line_items =
        Bounties.generate_line_items(
          %{owner: owner, amount: amount},
          recipient: recipient
        )

      platform_fee = Enum.find(line_items, &(&1.type == :fee and String.contains?(&1.title, "platform fee")))
      assert Money.equal?(platform_fee.amount, Money.new(500, :USD))
      assert platform_fee.title == "Algora platform fee (5%)"

      payout = Enum.find(line_items, &(&1.type == :payout))
      assert Money.equal?(payout.amount, amount)
      assert payout.title == "Payment to @recipient"
    end

    test "calculates line items correctly with claims" do
      owner = insert!(:user, fee_pct: 5)
      solver1 = insert!(:user, provider_login: "solver1")
      solver2 = insert!(:user, provider_login: "solver2")
      amount = Money.new(10_000, :USD)

      claims = [
        build(:claim, user: solver1, group_share: Decimal.new("0.60")),
        build(:claim, user: solver2, group_share: Decimal.new("0.40"))
      ]

      line_items =
        Bounties.generate_line_items(
          %{owner: owner, amount: amount},
          claims: claims
        )

      platform_fee = Enum.find(line_items, &(&1.type == :fee and String.contains?(&1.title, "platform fee")))
      assert Money.equal?(platform_fee.amount, Money.new(500, :USD))

      [payout1, payout2] = Enum.filter(line_items, &(&1.type == :payout))
      assert Money.equal?(payout1.amount, Money.new(6000, :USD))
      assert payout1.title == "Payment to @solver1"
      assert Money.equal?(payout2.amount, Money.new(4000, :USD))
      assert payout2.title == "Payment to @solver2"
    end

    test "includes ticket reference in description when provided" do
      owner = insert!(:user, fee_pct: 5)
      recipient = insert!(:user, provider_login: "recipient")
      amount = Money.new(10_000, :USD)
      ticket_ref = %{owner: "owner", repo: "repo", number: 123}

      line_items =
        Bounties.generate_line_items(
          %{owner: owner, amount: amount},
          recipient: recipient,
          ticket_ref: ticket_ref
        )

      payout = Enum.find(line_items, &(&1.type == :payout))
      assert payout.description == "repo#123"
    end
  end
end
