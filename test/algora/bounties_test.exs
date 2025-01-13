defmodule Algora.BountiesTest do
  use Algora.DataCase
  use Oban.Testing, repo: Algora.Repo

  import Algora.Factory
  import Money.Sigil

  def setup_github_mocks(_context) do
    import Algora.Mocks.GithubMock

    setup_installation_token()
    setup_repository_permissions()
    setup_create_issue_comment()
    setup_get_user_by_username()
    setup_get_issue()
    setup_get_repository()
    :ok
  end

  def setup_stripe_mocks(_context) do
    import Algora.Mocks.StripeMock

    setup_create_session()
    :ok
  end

  describe "bounties" do
    setup [:setup_github_mocks, :setup_stripe_mocks]

    test "create" do
      creator = insert!(:user)
      owner = insert!(:user)
      _installation = insert!(:installation, owner: creator)
      _identity = insert!(:identity, user: creator, provider_email: creator.email)
      repo = insert!(:repository, %{user: owner})
      ticket = insert!(:ticket, %{repository: repo})
      amount = ~M[4000]usd

      bounty_params =
        %{
          ticket_ref: %{owner: owner.handle, repo: repo.name, number: ticket.number},
          owner: owner,
          creator: creator,
          amount: amount
        }

      {:ok, bounty} = Algora.Bounties.create_bounty(bounty_params, [])
      {:ok, tip} = Algora.Bounties.create_tip(%{amount: amount, owner: owner, creator: creator, recipient: creator})

      assert bounty
      assert tip

      assert_activity_names([])
      assert_activity_names_for_user(creator.id, [])
      assert_activity_names_for_user(owner.id, [])
    end

    test "query" do
      [bounty | _] =
        Enum.map(1..10, fn _n ->
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

          {:ok, bounty} = Algora.Bounties.create_bounty(bounty_params, [])
          bounty
        end)

      assert Algora.Bounties.list_bounties(
               owner_id: bounty.owner_id,
               tech_stack: ["elixir"],
               status: :open
             )

      assert Algora.Bounties.fetch_stats(bounty.owner_id)
      assert Algora.Bounties.fetch_stats()
      assert Algora.Bounties.PrizePool.list()
    end
  end
end
