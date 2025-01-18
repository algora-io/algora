defmodule Algora.Bounties do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Jobs
  alias Algora.Bounties.Tip
  alias Algora.FeeTier
  alias Algora.Github
  alias Algora.MoneyUtils
  alias Algora.Organizations.Member
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace
  alias Algora.Workspace.Ticket

  require Logger

  def base_query, do: Bounty

  @type criterion ::
          {:limit, non_neg_integer()}
          | {:owner_id, integer()}
          | {:status, :open | :paid}
          | {:tech_stack, [String.t()]}

  def broadcast do
    Phoenix.PubSub.broadcast(Algora.PubSub, "bounties:all", :bounties_updated)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Algora.PubSub, "bounties:all")
  end

  @spec do_create_bounty(%{creator: User.t(), owner: User.t(), amount: Money.t(), ticket: Ticket.t()}) ::
          {:ok, Bounty.t()} | {:error, atom()}
  defp do_create_bounty(%{creator: creator, owner: owner, amount: amount, ticket: ticket}) do
    changeset =
      Bounty.changeset(%Bounty{}, %{
        amount: amount,
        ticket_id: ticket.id,
        owner_id: owner.id,
        creator_id: creator.id
      })

    case Repo.insert(changeset) do
      {:ok, bounty} ->
        {:ok, bounty}

      {:error, %{errors: [ticket_id: {_, [constraint: :unique, constraint_name: _]}]}} ->
        {:error, :already_exists}

      {:error, _changeset} = error ->
        error
    end
  end

  @spec create_bounty(
          %{
            creator: User.t(),
            owner: User.t(),
            amount: Money.t(),
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}
          },
          opts :: [installation_id: integer()]
        ) ::
          {:ok, Bounty.t()} | {:error, atom()}
  def create_bounty(
        %{
          creator: creator,
          owner: owner,
          amount: amount,
          ticket_ref: %{owner: repo_owner, repo: repo_name, number: number} = ticket_ref
        },
        opts \\ []
      ) do
    installation_id = opts[:installation_id]

    token_res =
      if installation_id,
        do: Github.get_installation_token(installation_id),
        else: Accounts.get_access_token(creator)

    Repo.transact(fn ->
      with {:ok, token} <- token_res,
           {:ok, ticket} <- Workspace.ensure_ticket(token, repo_owner, repo_name, number),
           {:ok, bounty} <- do_create_bounty(%{creator: creator, owner: owner, amount: amount, ticket: ticket}),
           {:ok, _job} <-
             notify_bounty(%{owner: owner, bounty: bounty, ticket_ref: ticket_ref}, installation_id: installation_id) do
        broadcast()
        {:ok, bounty}
      else
        {:error, _reason} = error -> error
      end
    end)
  end

  @spec notify_bounty(
          %{
            owner: User.t(),
            bounty: Bounty.t(),
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}
          },
          opts :: [installation_id: integer()]
        ) ::
          {:ok, Oban.Job.t()} | {:error, atom()}
  def notify_bounty(%{owner: owner, bounty: bounty, ticket_ref: ticket_ref}, opts \\ []) do
    %{
      owner_login: owner.provider_login,
      amount: Money.to_string!(bounty.amount, no_fraction_if_integer: true),
      ticket_ref: %{owner: ticket_ref.owner, repo: ticket_ref.repo, number: ticket_ref.number},
      installation_id: opts[:installation_id]
    }
    |> Jobs.NotifyBounty.new()
    |> Oban.insert()
  end

  @spec do_claim_bounty(%{
          user: User.t(),
          target: Ticket.t(),
          source: Ticket.t(),
          status: :pending | :approved | :rejected | :paid,
          type: :pull_request | :review | :video | :design | :article
        }) ::
          {:ok, Claim.t()} | {:error, atom()}
  defp do_claim_bounty(%{user: user, target: target, source: source, status: status, type: type}) do
    # TODO: ensure user is pull request author
    changeset =
      Claim.changeset(%Claim{}, %{
        target_id: target.id,
        source_id: source.id,
        user_id: user.id,
        type: type,
        status: status,
        url: source.url
      })

    case Repo.insert(changeset) do
      {:ok, claim} ->
        {:ok, claim}

      {:error, %{errors: [target_id: {_, [constraint: :unique, constraint_name: _]}]}} ->
        {:error, :already_exists}

      {:error, _changeset} = error ->
        error
    end
  end

  @spec claim_bounty(
          %{
            user: User.t(),
            target_ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
            source_ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
            status: :pending | :approved | :rejected | :paid,
            type: :pull_request | :review | :video | :design | :article
          },
          opts :: [installation_id: integer()]
        ) ::
          {:ok, Bounty.t()} | {:error, atom()}
  def claim_bounty(
        %{
          user: user,
          target_ticket_ref: %{owner: target_repo_owner, repo: target_repo_name, number: target_number},
          source_ticket_ref: %{owner: source_repo_owner, repo: source_repo_name, number: source_number},
          status: status,
          type: type
        },
        opts \\ []
      ) do
    installation_id = opts[:installation_id]

    token_res =
      if installation_id,
        do: Github.get_installation_token(installation_id),
        else: Accounts.get_access_token(user)

    Repo.transact(fn ->
      with {:ok, token} <- token_res,
           {:ok, target} <- Workspace.ensure_ticket(token, target_repo_owner, target_repo_name, target_number),
           {:ok, source} <- Workspace.ensure_ticket(token, source_repo_owner, source_repo_name, source_number),
           {:ok, claim} <- do_claim_bounty(%{user: user, target: target, source: source, status: status, type: type}),
           {:ok, _job} <- notify_claim(%{claim: claim}, installation_id: installation_id) do
        broadcast()
        {:ok, claim}
      else
        {:error, _reason} = error -> error
      end
    end)
  end

  @spec notify_claim(
          %{claim: Claim.t()},
          opts :: [installation_id: integer()]
        ) ::
          {:ok, Oban.Job.t()} | {:error, atom()}
  def notify_claim(%{claim: claim}, opts \\ []) do
    %{claim_id: claim.id, installation_id: opts[:installation_id]}
    |> Jobs.NotifyClaim.new()
    |> Oban.insert()
  end

  @spec create_tip_intent(
          %{
            recipient: String.t(),
            amount: Money.t(),
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}
          },
          opts :: [installation_id: integer()]
        ) ::
          {:ok, String.t()} | {:error, atom()}
  def create_tip_intent(
        %{recipient: recipient, amount: amount, ticket_ref: %{owner: owner, repo: repo, number: number}},
        opts \\ []
      ) do
    query =
      URI.encode_query(
        amount: Money.to_decimal(amount),
        recipient: recipient,
        owner: owner,
        repo: repo,
        number: number
      )

    url = AlgoraWeb.Endpoint.url() <> "/tip" <> "?" <> query

    %{
      url: url,
      ticket_ref: %{owner: owner, repo: repo, number: number},
      installation_id: opts[:installation_id]
    }
    |> Jobs.NotifyTipIntent.new()
    |> Oban.insert()
  end

  @spec create_tip(
          %{creator: User.t(), owner: User.t(), recipient: User.t(), amount: Money.t()},
          opts :: [ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}]
        ) ::
          {:ok, String.t()} | {:error, atom()}
  def create_tip(%{creator: creator, owner: owner, recipient: recipient, amount: amount}, opts \\ []) do
    changeset =
      Tip.changeset(%Tip{}, %{
        amount: amount,
        owner_id: owner.id,
        creator_id: creator.id,
        recipient_id: recipient.id
      })

    Repo.transact(fn ->
      with {:ok, tip} <- Repo.insert(changeset) do
        create_payment_session(
          %{creator: creator, amount: amount, description: "Tip payment for OSS contributions"},
          ticket_ref: opts[:ticket_ref],
          tip_id: tip.id,
          recipient: recipient
        )
      end
    end)
  end

  @spec reward_bounty(
          %{
            creator: User.t(),
            amount: Money.t(),
            bounty_id: String.t(),
            claims: [Claim.t()]
          },
          opts :: [ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}]
        ) ::
          {:ok, String.t()} | {:error, atom()}
  def reward_bounty(%{creator: creator, amount: amount, bounty_id: bounty_id, claims: claims}, opts \\ []) do
    create_payment_session(
      %{creator: creator, amount: amount, description: "Bounty payment for OSS contributions"},
      ticket_ref: opts[:ticket_ref],
      bounty_id: bounty_id,
      claims: claims
    )
  end

  @spec create_payment_session(
          %{creator: User.t(), amount: Money.t(), description: String.t()},
          opts :: [
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
            tip_id: String.t(),
            bounty_id: String.t(),
            claims: [Claim.t()],
            recipient: User.t()
          ]
        ) ::
          {:ok, String.t()} | {:error, atom()}
  def create_payment_session(%{creator: creator, amount: amount, description: description}, opts \\ []) do
    ticket_ref = opts[:ticket_ref]
    recipient = opts[:recipient]
    claims = opts[:claims]

    tx_group_id = Nanoid.generate()

    # Calculate fees
    currency = to_string(amount.currency)
    platform_fee_pct = FeeTier.calculate_fee_percentage(Money.zero(:USD))
    transaction_fee_pct = Payments.get_transaction_fee_pct()

    platform_fee = Money.mult!(amount, platform_fee_pct)
    transaction_fee = Money.mult!(amount, transaction_fee_pct)
    total_fee = Money.add!(platform_fee, transaction_fee)
    gross_amount = Money.add!(amount, total_fee)

    line_items =
      if recipient do
        [
          %{
            price_data: %{
              unit_amount: MoneyUtils.to_minor_units(amount),
              currency: currency,
              product_data: %{
                name: "Payment to @#{recipient.provider_login}",
                description: if(ticket_ref, do: "#{ticket_ref[:owner]}/#{ticket_ref[:repo]}##{ticket_ref[:number]}"),
                images: [recipient.avatar_url]
              }
            },
            quantity: 1
          }
        ]
      else
        []
      end ++
        Enum.map(claims, fn claim ->
          %{
            price_data: %{
              # TODO: ensure shares are normalized
              unit_amount: amount |> Money.mult!(claim.group_share) |> MoneyUtils.to_minor_units(),
              currency: currency,
              product_data: %{
                name: "Payment to @#{claim.user.provider_login}",
                description: if(ticket_ref, do: "#{ticket_ref[:owner]}/#{ticket_ref[:repo]}##{ticket_ref[:number]}"),
                images: [claim.user.avatar_url]
              }
            },
            quantity: 1
          }
        end) ++
        [
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
      with {:ok, _charge} <-
             initialize_charge(%{
               id: Nanoid.generate(),
               tip_id: opts[:tip_id],
               bounty_id: opts[:bounty_id],
               claim_id: nil,
               user_id: creator.id,
               gross_amount: gross_amount,
               net_amount: amount,
               total_fee: total_fee,
               line_items: line_items,
               group_id: tx_group_id
             }),
           {:ok, _transactions} <-
             create_transaction_pairs(%{
               claims: opts[:claims] || [],
               tip_id: opts[:tip_id],
               bounty_id: opts[:bounty_id],
               amount: amount,
               creator_id: creator.id,
               group_id: tx_group_id
             }),
           {:ok, session} <-
             Payments.create_stripe_session(line_items, %{
               description: description,
               metadata: %{"version" => "2", "group_id" => tx_group_id}
             }) do
        {:ok, session.url}
      end
    end)
  end

  defp initialize_charge(%{
         id: id,
         tip_id: tip_id,
         bounty_id: bounty_id,
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
      tip_id: tip_id,
      bounty_id: bounty_id,
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
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:tip_id)
    |> foreign_key_constraint(:bounty_id)
    |> foreign_key_constraint(:claim_id)
    |> Repo.insert()
  end

  defp initialize_debit(%{
         id: id,
         tip_id: tip_id,
         bounty_id: bounty_id,
         claim_id: claim_id,
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
      tip_id: tip_id,
      bounty_id: bounty_id,
      claim_id: claim_id,
      user_id: user_id,
      gross_amount: amount,
      net_amount: amount,
      total_fee: Money.zero(:USD),
      linked_transaction_id: linked_transaction_id,
      group_id: group_id
    })
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:tip_id)
    |> foreign_key_constraint(:bounty_id)
    |> foreign_key_constraint(:claim_id)
    |> Repo.insert()
  end

  defp initialize_credit(%{
         id: id,
         tip_id: tip_id,
         bounty_id: bounty_id,
         claim_id: claim_id,
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
      tip_id: tip_id,
      bounty_id: bounty_id,
      claim_id: claim_id,
      user_id: user_id,
      gross_amount: amount,
      net_amount: amount,
      total_fee: Money.zero(:USD),
      linked_transaction_id: linked_transaction_id,
      group_id: group_id
    })
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:tip_id)
    |> foreign_key_constraint(:bounty_id)
    |> foreign_key_constraint(:claim_id)
    |> Repo.insert()
  end

  @spec apply_criteria(Ecto.Queryable.t(), [criterion()]) :: Ecto.Queryable.t()
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

  # Helper function to create transaction pairs
  defp create_transaction_pairs(%{claims: claims} = params) when length(claims) > 0 do
    Enum.reduce_while(claims, {:ok, []}, fn claim, {:ok, acc} ->
      params
      |> Map.put(:claim_id, claim.id)
      |> Map.put(:recipient_id, claim.user.id)
      |> create_single_transaction_pair()
      |> case do
        {:ok, transactions} -> {:cont, {:ok, transactions ++ acc}}
        error -> {:halt, error}
      end
    end)
  end

  defp create_transaction_pairs(params) do
    create_single_transaction_pair(params)
  end

  defp create_single_transaction_pair(params) do
    debit_id = Nanoid.generate()
    credit_id = Nanoid.generate()

    with {:ok, debit} <-
           initialize_debit(%{
             id: debit_id,
             tip_id: params.tip_id,
             bounty_id: params.bounty_id,
             claim_id: params.claim_id,
             amount: params.amount,
             user_id: params.creator_id,
             linked_transaction_id: credit_id,
             group_id: params.group_id
           }),
         {:ok, credit} <-
           initialize_credit(%{
             id: credit_id,
             tip_id: params.tip_id,
             bounty_id: params.bounty_id,
             claim_id: params.claim_id,
             amount: params.amount,
             user_id: params.recipient_id,
             linked_transaction_id: debit_id,
             group_id: params.group_id
           }) do
      {:ok, [debit, credit]}
    end
  end
end
