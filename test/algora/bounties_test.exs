defmodule Algora.BountiesTest do
  use Algora.DataCase
  use Oban.Testing, repo: Algora.Repo

  import Algora.Factory
  import Money.Sigil

  alias Algora.Activities.Notifier
  alias Algora.Activities.SendEmail

  describe "bounties" do
    test "create" do
      creator = insert!(:user)
      owner = insert!(:user)
      recipient = insert!(:user)
      installation = insert!(:installation, owner: creator)
      _installation = insert!(:installation, owner: owner)
      _installation = insert!(:installation, owner: recipient)
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

      assert {:ok, bounty} = Algora.Bounties.create_bounty(bounty_params, [])

      assert {:ok, claims} =
               Algora.Bounties.claim_bounty(
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
               Algora.Bounties.reward_bounty(
                 %{
                   owner: owner,
                   amount: ~M[4000]usd,
                   bounty_id: bounty.id,
                   claims: claims
                 },
                 installation_id: installation.id
               )

      assert {:ok, _stripe_session_url} =
               Algora.Bounties.create_tip(
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
      assert tip.notify_users == [recipient.id]
      assert activity = Algora.Activities.get_with_preloaded_assoc(tip.assoc_name, tip.id)
      assert activity.assoc.__meta__.schema == Algora.Bounties.Tip
      assert activity.assoc.creator.id == creator.id

      assert_enqueued(worker: Notifier, args: %{"activity_id" => bounty.id})
      refute_enqueued(worker: SendEmail, args: %{"activity_id" => bounty.id})

      Enum.map(all_enqueued(worker: Notifier), fn job ->
        perform_job(Notifier, job.args)
      end)

      assert_enqueued(worker: SendEmail, args: %{"activity_id" => bounty.id})
    end

    test "query" do
      {:ok, bounty} =
        Enum.reduce(1..10, nil, fn _n, _acc ->
          creator = insert!(:user)
          owner = insert!(:user)
          _installation = insert!(:installation, owner: creator)
          _identity = insert!(:identity, user: creator, provider_email: creator.email)
          repo = insert!(:repository, %{user: owner})
          ticket = insert!(:ticket, %{repository: repo})
          amount = ~M[100]usd

          bounty_params =
            %{
              ticket_ref: %{owner: owner.handle, repo: repo.name, number: ticket.number},
              owner: owner,
              creator: creator,
              amount: amount
            }

          Algora.Bounties.create_bounty(bounty_params, [])
        end)

      assert Algora.Bounties.list_bounties(
               owner_id: bounty.owner_id,
               tech_stack: ["elixir"],
               status: :open
             )

      # assert Algora.Bounties.fetch_stats(bounty.owner_id)
      # assert Algora.Bounties.fetch_stats()
      assert Algora.Bounties.PrizePool.list()
    end
  end
end
