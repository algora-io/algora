defmodule Algora.Bounties do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Tip
  alias Algora.FeeTier
  alias Algora.MoneyUtils
  alias Algora.Organizations.Member
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace
  alias Algora.Workspace.Ticket

  def broadcast! do
    Phoenix.PubSub.broadcast!(Algora.PubSub, "bounties:all", :bounties_updated)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Algora.PubSub, "bounties:all")
  end

  @spec create_bounty(%{
          creator: User.t(),
          owner: User.t(),
          amount: Money.t(),
          ticket: Ticket.t()
        }) ::
          {:ok, Bounty.t()} | {:error, atom()}
  def create_bounty(%{creator: creator, owner: owner, amount: amount, ticket: ticket}) do
    changeset =
      Bounty.changeset(%Bounty{}, %{
        amount: amount,
        ticket_id: ticket.id,
        owner_id: owner.id,
        creator_id: creator.id
      })

    case Repo.insert(changeset) do
      {:ok, bounty} ->
        broadcast!()
        {:ok, bounty}

      {:error, %{errors: [ticket_id: {_, [constraint: :unique, constraint_name: _]}]}} ->
        {:error, :already_exists}

      {:error, _changeset} ->
        {:error, :internal_server_error}
    end
  end

  @spec create_bounty(%{
          creator: User.t(),
          owner: User.t(),
          amount: Money.t(),
          ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}
        }) ::
          {:ok, Bounty.t()} | {:error, atom()}
  def create_bounty(%{
        creator: creator,
        owner: owner,
        amount: amount,
        ticket_ref: %{owner: repo_owner, repo: repo_name, number: number}
      }) do
    with {:ok, token} <- Accounts.get_access_token(creator),
         {:ok, ticket} <- Workspace.ensure_ticket(token, repo_owner, repo_name, number) do
      create_bounty(%{creator: creator, owner: owner, amount: amount, ticket: ticket})
    else
      {:error, _reason} = error -> error
    end
  end

  @spec create_tip(%{
          creator: User.t(),
          owner: User.t(),
          recipient: User.t(),
          amount: Money.t()
        }) ::
          {:ok, String.t()} | {:error, atom()}
  def create_tip(%{creator: creator, owner: owner, recipient: recipient, amount: amount}) do
    changeset =
      Tip.changeset(%Tip{}, %{
        amount: amount,
        owner_id: owner.id,
        creator_id: creator.id,
        recipient_id: recipient.id
      })

    # Initialize transaction IDs
    charge_id = Nanoid.generate()
    debit_id = Nanoid.generate()
    credit_id = Nanoid.generate()
    tx_group_id = Nanoid.generate()

    # Calculate fees
    currency = to_string(amount.currency)
    total_paid = Payments.get_total_paid(owner.id, recipient.id)
    platform_fee_pct = FeeTier.calculate_fee_percentage(total_paid)
    transaction_fee_pct = Payments.get_transaction_fee_pct()

    platform_fee = Money.mult!(amount, platform_fee_pct)
    transaction_fee = Money.mult!(amount, transaction_fee_pct)
    total_fee = Money.add!(platform_fee, transaction_fee)
    gross_amount = Money.add!(amount, total_fee)

    line_items = [
      %{
        price_data: %{
          unit_amount: MoneyUtils.to_minor_units(amount),
          currency: currency,
          product_data: %{
            name: "Payment to @#{recipient.provider_login}",
            # TODO:
            # description: nil,
            images: [recipient.avatar_url]
          }
        },
        quantity: 1
      },
      %{
        price_data: %{
          unit_amount: MoneyUtils.to_minor_units(Money.mult!(amount, platform_fee_pct)),
          currency: currency,
          product_data: %{name: "Algora platform fee (#{Util.format_pct(platform_fee_pct)})"}
        },
        quantity: 1
      },
      %{
        price_data: %{
          unit_amount: MoneyUtils.to_minor_units(Money.mult!(amount, transaction_fee_pct)),
          currency: currency,
          product_data: %{name: "Transaction fee (#{Util.format_pct(transaction_fee_pct)})"}
        },
        quantity: 1
      }
    ]

    Repo.transact(fn ->
      with {:ok, tip} <- Repo.insert(changeset),
           {:ok, _charge} <-
             initialize_charge(%{
               id: charge_id,
               tip: tip,
               user_id: creator.id,
               gross_amount: gross_amount,
               net_amount: amount,
               total_fee: total_fee,
               line_items: line_items,
               group_id: tx_group_id
             }),
           {:ok, _debit} <-
             initialize_debit(%{
               id: debit_id,
               tip: tip,
               amount: amount,
               user_id: creator.id,
               linked_transaction_id: credit_id,
               group_id: tx_group_id
             }),
           {:ok, _credit} <-
             initialize_credit(%{
               id: credit_id,
               tip: tip,
               amount: amount,
               user_id: recipient.id,
               linked_transaction_id: debit_id,
               group_id: tx_group_id
             }),
           {:ok, session} <-
             Payments.create_stripe_session(line_items, %{
               # Mandatory for some countries like India
               description: "Tip payment for OSS contributions",
               metadata: %{"version" => "2", "group_id" => tx_group_id}
             }) do
        {:ok, session.url}
      end
    end)
  end

  defp initialize_charge(%{
         id: id,
         tip: tip,
         user_id: user_id,
         gross_amount: gross_amount,
         net_amount: net_amount,
         total_fee: total_fee,
         line_items: line_items,
         group_id: group_id
       }) do
    %Transaction{}
    |> change(%{
      id: id,
      provider: "stripe",
      type: :charge,
      status: :initialized,
      tip_id: tip.id,
      user_id: user_id,
      gross_amount: gross_amount,
      net_amount: net_amount,
      total_fee: total_fee,
      line_items: line_items,
      group_id: group_id
    })
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
    |> Algora.Validations.validate_positive(:total_fee)
    |> foreign_key_constraint(:tip_id)
    |> foreign_key_constraint(:user_id)
    |> Repo.insert()
  end

  defp initialize_debit(%{
         id: id,
         tip: tip,
         amount: amount,
         user_id: user_id,
         linked_transaction_id: linked_transaction_id,
         group_id: group_id
       }) do
    %Transaction{}
    |> change(%{
      id: id,
      provider: "stripe",
      type: :debit,
      status: :initialized,
      tip_id: tip.id,
      user_id: user_id,
      gross_amount: amount,
      net_amount: amount,
      total_fee: Money.zero(:USD),
      linked_transaction_id: linked_transaction_id,
      group_id: group_id
    })
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
    |> foreign_key_constraint(:tip_id)
    |> foreign_key_constraint(:user_id)
    |> Repo.insert()
  end

  defp initialize_credit(%{
         id: id,
         tip: tip,
         amount: amount,
         user_id: user_id,
         linked_transaction_id: linked_transaction_id,
         group_id: group_id
       }) do
    %Transaction{}
    |> change(%{
      id: id,
      provider: "stripe",
      type: :credit,
      status: :initialized,
      tip_id: tip.id,
      user_id: user_id,
      gross_amount: amount,
      net_amount: amount,
      total_fee: Money.zero(:USD),
      linked_transaction_id: linked_transaction_id,
      group_id: group_id
    })
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
    |> foreign_key_constraint(:tip_id)
    |> foreign_key_constraint(:user_id)
    |> Repo.insert()
  end

  def base_query, do: Bounty

  @type criteria :: %{
          optional(:limit) => non_neg_integer(),
          optional(:owner_id) => integer(),
          optional(:status) => :open | :paid,
          optional(:tech_stack) => [String.t()]
        }
  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:limit, limit}, query ->
        from([b] in query, limit: ^limit)

      {:owner_id, owner_id}, query ->
        from([b] in query, where: b.owner_id == ^owner_id)

      {:status, status}, query ->
        from([b] in query, where: b.status == ^status)

      {:tech_stack, tech_stack}, query ->
        from([b, o: o] in query,
          where:
            fragment(
              "EXISTS (SELECT 1 FROM UNNEST(?::citext[]) t1 WHERE t1 = ANY(?::citext[]))",
              o.tech_stack,
              ^tech_stack
            )
        )

      _, query ->
        query
    end)
  end

  @spec list_bounties_with(base_query :: Ecto.Query.t(), criteria :: criteria()) :: [map()]
  def list_bounties_with(base_query, criteria \\ []) do
    criteria = Keyword.merge([order: :date, limit: 10], criteria)

    base_bounties = select(base_query, [b], b.id)

    from(b in Bounty)
    |> join(:inner, [b], bb in subquery(base_bounties), on: b.id == bb.id)
    |> join(:inner, [b], t in assoc(b, :ticket), as: :t)
    |> join(:inner, [b], o in assoc(b, :owner), as: :o)
    |> join(:left, [t: t], r in assoc(t, :repository), as: :r)
    |> join(:left, [r: r], ro in assoc(r, :user), as: :ro)
    |> apply_criteria(criteria)
    |> order_by([b], desc: b.amount, desc: b.inserted_at, desc: b.id)
    |> select([b, o: o, t: t, ro: ro, r: r], %{
      id: b.id,
      inserted_at: b.inserted_at,
      amount: b.amount,
      owner: %{
        id: o.id,
        name: o.name,
        handle: o.handle,
        avatar_url: o.avatar_url,
        tech_stack: o.tech_stack
      },
      ticket: %{
        id: t.id,
        title: t.title,
        number: t.number,
        url: t.url
      },
      repository: %{
        id: r.id,
        name: r.name,
        owner: %{
          id: ro.id,
          login: ro.provider_login
        }
      }
    })
    |> Repo.all()
  end

  def awarded_to_user(user_id) do
    from b in Bounty,
      join: t in Transaction,
      on: t.bounty_id == b.id,
      where: t.user_id == ^user_id and t.type == :credit and t.status == :succeeded
  end

  def list_bounties_awarded_to_user(user_id, criteria \\ []) do
    user_id
    |> awarded_to_user()
    |> list_bounties_with(criteria)
  end

  def list_bounties(criteria \\ []) do
    list_bounties_with(base_query(), criteria)
  end

  def fetch_stats(org_id \\ nil) do
    open_bounties_query = Bounty.filter_by_org_id(Bounty.open(), org_id)
    rewarded_bounties_query = Bounty.filter_by_org_id(Bounty.completed(), org_id)
    rewarded_claims_query = Claim.filter_by_org_id(Claim.rewarded(), org_id)
    members_query = Member.filter_by_org_id(Member, org_id)

    open_bounties = Repo.aggregate(open_bounties_query, :count, :id)
    open_bounties_amount = Repo.aggregate(open_bounties_query, :sum, :amount) || Money.zero(:USD)

    total_awarded = Repo.aggregate(rewarded_bounties_query, :sum, :amount) || Money.zero(:USD)
    completed_bounties = Repo.aggregate(rewarded_bounties_query, :count, :id)

    solvers_count_last_month =
      rewarded_claims_query
      |> where([c], c.inserted_at >= fragment("NOW() - INTERVAL '1 month'"))
      |> Repo.aggregate(
        :count,
        :user_id,
        distinct: true
      )

    solvers_count = Repo.aggregate(rewarded_claims_query, :count, :user_id, distinct: true)
    solvers_diff = solvers_count - solvers_count_last_month

    members_count = Repo.aggregate(members_query, :count, :id)

    %{
      open_bounties_amount: open_bounties_amount,
      open_bounties_count: open_bounties,
      total_awarded: total_awarded,
      completed_bounties_count: completed_bounties,
      solvers_count: solvers_count,
      solvers_diff: solvers_diff,
      members_count: members_count,
      # TODO
      reviews_count: 4
    }
  end
end
