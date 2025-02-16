defmodule Algora.Bounties do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties.Attempt
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Jobs
  alias Algora.Bounties.LineItem
  alias Algora.Bounties.Tip
  alias Algora.FeeTier
  alias Algora.Github
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
          | {:ticket_id, String.t()}
          | {:owner_id, String.t()}
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

    changeset
    |> Repo.insert_with_activity(%{
      type: :bounty_posted,
      notify_users: [creator.id]
    })
    |> case do
      {:ok, bounty} ->
        {:ok, bounty}

      {:error, %{errors: [ticket_id: {_, [constraint: :unique, constraint_name: _]}]}} ->
        {:error, :already_exists}

      {:error, _changeset} = error ->
        error
    end
  end

  @type strategy :: :create | :set | :increase

  @spec strategy_to_action(Bounty.t() | nil, strategy() | nil) :: {:ok, strategy()} | {:error, atom()}
  defp strategy_to_action(bounty, strategy) do
    case {bounty, strategy} do
      {_, nil} -> strategy_to_action(bounty, :increase)
      {nil, _} -> {:ok, :create}
      {_existing, :create} -> {:error, :already_exists}
      {_existing, strategy} -> {:ok, strategy}
    end
  end

  @spec create_bounty(
          %{
            creator: User.t(),
            owner: User.t(),
            amount: Money.t(),
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}
          },
          opts :: [
            strategy: strategy(),
            installation_id: integer(),
            command_id: integer(),
            command_source: :ticket | :comment
          ]
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
    command_id = opts[:command_id]

    token_res =
      if installation_id,
        do: Github.get_installation_token(installation_id),
        else: Accounts.get_access_token(creator)

    Repo.transact(fn ->
      with {:ok, token} <- token_res,
           {:ok, ticket} <- Workspace.ensure_ticket(token, repo_owner, repo_name, number),
           existing = Repo.get_by(Bounty, owner_id: owner.id, ticket_id: ticket.id),
           {:ok, strategy} <- strategy_to_action(existing, opts[:strategy]),
           {:ok, bounty} <-
             (case strategy do
                :create -> do_create_bounty(%{creator: creator, owner: owner, amount: amount, ticket: ticket})
                :set -> existing |> Bounty.changeset(%{amount: amount}) |> Repo.update()
                :increase -> existing |> Bounty.changeset(%{amount: Money.add!(existing.amount, amount)}) |> Repo.update()
              end),
           {:ok, _job} <-
             notify_bounty(%{owner: owner, bounty: bounty, ticket_ref: ticket_ref},
               installation_id: installation_id,
               command_id: command_id,
               command_source: opts[:command_source]
             ) do
        broadcast()
        {:ok, bounty}
      else
        {:error, _reason} = error -> error
      end
    end)
  end

  @spec get_response_body(
          bounties :: list(Bounty.t()),
          ticket_ref :: %{owner: String.t(), repo: String.t(), number: integer()},
          attempts :: list(Attempt.t())
        ) :: String.t()
  def get_response_body(bounties, ticket_ref, attempts) do
    header =
      Enum.map_join(bounties, "\n", fn bounty ->
        "## 💎 #{bounty.amount} bounty [• #{bounty.owner.name}](#{User.url(bounty.owner)})"
      end)

    attempts_table =
      if Enum.empty?(attempts) do
        ""
      else
        """

        | Attempt | Started (UTC) |
        | --- | --- |
        #{Enum.map_join(attempts, "\n", fn attempt -> "| #{get_attempt_emoji(attempt)} @#{attempt.user.provider_login} | #{Calendar.strftime(attempt.inserted_at, "%b %d, %Y, %I:%M:%S %p")} |" end)}
        """
      end

    """
    #{header}
    ### Steps to solve:
    1. **Start working**: Comment `/attempt ##{ticket_ref[:number]}` with your implementation plan
    2. **Submit work**: Create a pull request including `/claim ##{ticket_ref[:number]}` in the PR body to claim the bounty
    3. **Receive payment**: 100% of the bounty is received 2-5 days post-reward. [Make sure you are eligible for payouts](https://docs.algora.io/bounties/payments#supported-countries-regions)

    Thank you for contributing to #{ticket_ref[:owner]}/#{ticket_ref[:repo]}!
    #{attempts_table}
    """
  end

  def refresh_bounty_response(token, ticket_ref, ticket) do
    bounties = list_bounties(ticket_id: ticket.id)
    attempts = list_attempts_for_ticket(ticket.id)
    body = get_response_body(bounties, ticket_ref, attempts)

    Workspace.refresh_command_response(%{
      token: token,
      ticket_ref: ticket_ref,
      ticket: ticket,
      body: body,
      command_type: :bounty
    })
  end

  @spec notify_bounty(
          %{
            owner: User.t(),
            bounty: Bounty.t(),
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}
          },
          opts :: [installation_id: integer(), command_id: integer(), command_source: :ticket | :comment]
        ) ::
          {:ok, Oban.Job.t()} | {:error, atom()}
  def notify_bounty(%{owner: owner, bounty: bounty, ticket_ref: ticket_ref}, opts \\ []) do
    %{
      owner_login: owner.provider_login,
      amount: Money.to_string!(bounty.amount, no_fraction_if_integer: true),
      ticket_ref: %{owner: ticket_ref.owner, repo: ticket_ref.repo, number: ticket_ref.number},
      installation_id: opts[:installation_id],
      command_id: opts[:command_id],
      command_source: opts[:command_source]
    }
    |> Jobs.NotifyBounty.new()
    |> Oban.insert()
  end

  @spec do_claim_bounty(%{
          provider_login: String.t(),
          token: String.t(),
          target: Ticket.t(),
          source: Ticket.t(),
          group_id: String.t() | nil,
          group_share: Decimal.t(),
          status: :pending | :approved | :rejected | :paid,
          type: :pull_request | :review | :video | :design | :article
        }) ::
          {:ok, Claim.t()} | {:error, atom()}
  defp do_claim_bounty(%{
         provider_login: provider_login,
         token: token,
         target: target,
         source: source,
         group_id: group_id,
         group_share: group_share,
         status: status,
         type: type
       }) do
    with {:ok, user} <- Workspace.ensure_user(token, provider_login),
         activity_attrs = %{type: :claim_submitted, notify_users: [user.id]},
         {:ok, claim} <-
           Repo.insert_with_activity(
             Claim.changeset(%Claim{}, %{
               target_id: target.id,
               source_id: source.id,
               user_id: user.id,
               type: type,
               status: status,
               url: source.url,
               group_id: group_id,
               group_share: group_share
             }),
             activity_attrs
           ) do
      {:ok, claim}
    else
      {:error, %{errors: [target_id: {_, [constraint: :unique, constraint_name: _]}]}} ->
        {:error, :already_exists}

      {:error, _reason} = error ->
        error
    end
  end

  @spec do_claim_bounties(%{
          provider_logins: [String.t()],
          token: String.t(),
          target: Ticket.t(),
          source: Ticket.t(),
          status: :pending | :approved | :rejected | :paid,
          type: :pull_request | :review | :video | :design | :article
        }) ::
          {:ok, [Claim.t()]} | {:error, atom()}
  defp do_claim_bounties(%{
         provider_logins: provider_logins,
         token: token,
         target: target,
         source: source,
         status: status,
         type: type
       }) do
    Enum.reduce_while(provider_logins, {:ok, []}, fn provider_login, {:ok, acc} ->
      group_id =
        case List.last(acc) do
          nil -> nil
          primary_claim -> primary_claim.group_id
        end

      case do_claim_bounty(%{
             provider_login: provider_login,
             token: token,
             target: target,
             source: source,
             status: status,
             type: type,
             group_id: group_id,
             group_share: Decimal.div(1, length(provider_logins))
           }) do
        {:ok, claim} -> {:cont, {:ok, [claim | acc]}}
        error -> {:halt, error}
      end
    end)
  end

  @spec claim_bounty(
          %{
            user: User.t(),
            coauthor_provider_logins: [String.t()],
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
          coauthor_provider_logins: coauthor_provider_logins,
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
           {:ok, [claim | _]} <-
             do_claim_bounties(%{
               provider_logins: [user.provider_login | coauthor_provider_logins],
               token: token,
               target: target,
               source: source,
               status: status,
               type: type
             }),
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
    %{claim_group_id: claim.group_id, installation_id: opts[:installation_id]}
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

    activity_attrs =
      %{
        type: :tip_awarded,
        notify_users: [recipient.id]
      }

    Repo.transact(fn ->
      with {:ok, tip} <- Repo.insert_with_activity(changeset, activity_attrs) do
        create_payment_session(
          %{owner: owner, amount: amount, description: "Tip payment for OSS contributions"},
          ticket_ref: opts[:ticket_ref],
          tip_id: tip.id,
          recipient: recipient
        )
      end
    end)
  end

  @spec reward_bounty(
          %{
            owner: User.t(),
            amount: Money.t(),
            bounty_id: String.t(),
            claims: [Claim.t()]
          },
          opts :: [ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}]
        ) ::
          {:ok, String.t()} | {:error, atom()}
  def reward_bounty(%{owner: owner, amount: amount, bounty_id: bounty_id, claims: claims}, opts \\ []) do
    Repo.transact(fn ->
      activity_attrs = %{type: :bounty_awarded}

      with {:ok, _activity} <- Algora.Activities.insert(%Bounty{id: bounty_id}, activity_attrs) do
        create_payment_session(
          %{owner: owner, amount: amount, description: "Bounty payment for OSS contributions"},
          ticket_ref: opts[:ticket_ref],
          bounty_id: bounty_id,
          claims: claims
        )
      end
    end)
  end

  @spec generate_line_items(
          %{amount: Money.t()},
          opts :: [
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
            claims: [Claim.t()],
            recipient: User.t()
          ]
        ) ::
          [LineItem.t()]
  def generate_line_items(%{amount: amount}, opts \\ []) do
    ticket_ref = opts[:ticket_ref]
    recipient = opts[:recipient]
    claims = opts[:claims] || []

    description = if(ticket_ref, do: "#{ticket_ref[:repo]}##{ticket_ref[:number]}")

    platform_fee_pct = FeeTier.calculate_fee_percentage(Money.zero(:USD))
    transaction_fee_pct = Payments.get_transaction_fee_pct()

    if recipient do
      [
        %LineItem{
          amount: amount,
          title: "Payment to @#{recipient.provider_login}",
          description: description,
          image: recipient.avatar_url,
          type: :payout
        }
      ]
    else
      []
    end ++
      Enum.map(claims, fn claim ->
        %LineItem{
          # TODO: ensure shares are normalized
          amount: Money.mult!(amount, claim.group_share),
          title: "Payment to @#{claim.user.provider_login}",
          description: description,
          image: claim.user.avatar_url,
          type: :payout
        }
      end) ++
      [
        %LineItem{
          amount: Money.mult!(amount, platform_fee_pct),
          title: "Algora platform fee (#{Util.format_pct(platform_fee_pct)})",
          type: :fee
        },
        %LineItem{
          amount: Money.mult!(amount, transaction_fee_pct),
          title: "Transaction fee (#{Util.format_pct(transaction_fee_pct)})",
          type: :fee
        }
      ]
  end

  @spec create_payment_session(
          %{owner: User.t(), amount: Money.t(), description: String.t()},
          opts :: [
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
            tip_id: String.t(),
            bounty_id: String.t(),
            claims: [Claim.t()],
            recipient: User.t()
          ]
        ) ::
          {:ok, String.t()} | {:error, atom()}
  def create_payment_session(%{owner: owner, amount: amount, description: description}, opts \\ []) do
    tx_group_id = Nanoid.generate()

    line_items =
      generate_line_items(%{amount: amount},
        ticket_ref: opts[:ticket_ref],
        recipient: opts[:recipient],
        claims: opts[:claims]
      )

    gross_amount = LineItem.gross_amount(line_items)

    Repo.transact(fn ->
      with {:ok, _charge} <-
             initialize_charge(%{
               id: Nanoid.generate(),
               tip_id: opts[:tip_id],
               bounty_id: opts[:bounty_id],
               claim_id: nil,
               user_id: owner.id,
               gross_amount: gross_amount,
               net_amount: amount,
               total_fee: Money.sub!(gross_amount, amount),
               line_items: line_items,
               group_id: tx_group_id
             }),
           {:ok, _transactions} <-
             create_transaction_pairs(%{
               claims: opts[:claims] || [],
               tip_id: opts[:tip_id],
               bounty_id: opts[:bounty_id],
               claim_id: nil,
               amount: amount,
               creator_id: owner.id,
               group_id: tx_group_id
             }),
           {:ok, session} <-
             line_items
             |> Enum.map(&LineItem.to_stripe/1)
             |> Payments.create_stripe_session(%{
               description: description,
               metadata: %{"version" => Payments.metadata_version(), "group_id" => tx_group_id}
             }) do
        {:ok, session.url}
      end
    end)
  end

  @spec create_invoice(
          %{owner: User.t(), amount: Money.t()},
          opts :: [
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
            tip_id: String.t(),
            bounty_id: String.t(),
            claims: [Claim.t()],
            recipient: User.t()
          ]
        ) ::
          {:ok, Stripe.Invoice.t()} | {:error, atom()}
  def create_invoice(%{owner: owner, amount: amount}, opts \\ []) do
    tx_group_id = Nanoid.generate()

    line_items =
      generate_line_items(%{amount: amount},
        ticket_ref: opts[:ticket_ref],
        recipient: opts[:recipient],
        claims: opts[:claims]
      )

    gross_amount = LineItem.gross_amount(line_items)

    Repo.transact(fn ->
      with {:ok, _charge} <-
             initialize_charge(%{
               id: Nanoid.generate(),
               tip_id: opts[:tip_id],
               bounty_id: opts[:bounty_id],
               claim_id: nil,
               user_id: owner.id,
               gross_amount: gross_amount,
               net_amount: amount,
               total_fee: Money.sub!(gross_amount, amount),
               line_items: line_items,
               group_id: tx_group_id
             }),
           {:ok, _transactions} <-
             create_transaction_pairs(%{
               claims: opts[:claims] || [],
               tip_id: opts[:tip_id],
               bounty_id: opts[:bounty_id],
               claim_id: nil,
               amount: amount,
               creator_id: owner.id,
               group_id: tx_group_id
             }),
           {:ok, customer} <- Payments.fetch_or_create_customer(owner),
           {:ok, invoice} <-
             Algora.Stripe.create_invoice(%{
               auto_advance: false,
               customer: customer.provider_id
             }),
           {:ok, _line_items} <-
             line_items
             |> Enum.map(&LineItem.to_invoice_item(&1, invoice, customer))
             |> Enum.reduce_while({:ok, []}, fn params, {:ok, acc} ->
               case Algora.Stripe.create_invoice_item(params) do
                 {:ok, item} -> {:cont, {:ok, [item | acc]}}
                 {:error, error} -> {:halt, {:error, error}}
               end
             end) do
        {:ok, invoice}
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
      line_items: Util.normalize_struct(line_items),
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

      {:ticket_id, ticket_id}, query ->
        from([b] in query, where: b.ticket_id == ^ticket_id)

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
    |> where([b], not is_nil(b.amount))
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

  @spec list_claims(list(String.t())) :: [Claim.t()]
  def list_claims(ticket_ids) do
    Repo.all(
      from c in Claim,
        join: t in assoc(c, :target),
        join: user in assoc(c, :user),
        left_join: s in assoc(c, :source),
        where: t.id in ^ticket_ids,
        select_merge: %{user: user, source: s}
    )
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
    zero_money = Money.zero(:USD, no_fraction_if_integer: true)

    open_bounties_query =
      from b in Bounty,
        join: u in assoc(b, :owner),
        where: u.id == ^org_id,
        where: b.status == :open

    rewards_query =
      from t in Transaction,
        where: t.type == :credit,
        where: t.status == :succeeded,
        join: lt in assoc(t, :linked_transaction),
        where: lt.type == :debit,
        where: lt.status == :succeeded,
        where: lt.user_id == ^org_id

    rewarded_bounties_query = distinct(rewards_query, :bounty_id)
    rewarded_tips_query = distinct(rewards_query, :tip_id)
    rewarded_contracts_query = distinct(rewards_query, :contract_id)
    rewarded_users_query = rewards_query |> distinct(true) |> select([:user_id])

    rewarded_users_last_month_query =
      from t in rewarded_users_query,
        where: t.succeeded_at >= fragment("NOW() - INTERVAL '1 month'"),
        except_all: ^from(t in rewarded_users_query, where: t.succeeded_at < fragment("NOW() - INTERVAL '1 month'"))

    members_query = Member.filter_by_org_id(Member, org_id)
    open_bounties = Repo.aggregate(open_bounties_query, :count, :id)
    open_bounties_amount = Repo.aggregate(open_bounties_query, :sum, :amount) || zero_money
    total_awarded_amount = Repo.aggregate(rewards_query, :sum, :net_amount) || zero_money
    rewarded_bounties_count = Repo.aggregate(rewarded_bounties_query, :count, :id)
    rewarded_tips_count = Repo.aggregate(rewarded_tips_query, :count, :id)
    rewarded_contracts_count = Repo.aggregate(rewarded_contracts_query, :count, :id)
    solvers_count_last_month = Repo.aggregate(rewarded_users_last_month_query, :count, :user_id)
    solvers_count = Repo.aggregate(rewarded_users_query, :count, :user_id)
    members_count = Repo.aggregate(members_query, :count, :id)

    %{
      open_bounties_amount: open_bounties_amount,
      open_bounties_count: open_bounties,
      total_awarded_amount: total_awarded_amount,
      rewarded_bounties_count: rewarded_bounties_count,
      rewarded_tips_count: rewarded_tips_count,
      rewarded_contracts_count: rewarded_contracts_count,
      solvers_count: solvers_count,
      solvers_diff: solvers_count - solvers_count_last_month,
      members_count: members_count
    }
  end

  # Helper function to create transaction pairs
  defp create_transaction_pairs(%{amount: amount, claims: claims} = params) when length(claims) > 0 do
    Enum.reduce_while(claims, {:ok, []}, fn claim, {:ok, acc} ->
      params
      |> Map.put(:claim_id, claim.id)
      |> Map.put(:recipient_id, claim.user.id)
      |> Map.put(:amount, Money.mult!(amount, claim.group_share))
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
             claim_id: params[:claim_id],
             amount: params.amount,
             user_id: params[:recipient_id],
             linked_transaction_id: debit_id,
             group_id: params.group_id
           }) do
      {:ok, [debit, credit]}
    end
  end

  @spec create_attempt(%{ticket: Ticket.t(), user: User.t()}) ::
          {:ok, Attempt.t()} | {:error, Ecto.Changeset.t()}
  def create_attempt(%{ticket: ticket, user: user}) do
    %Attempt{}
    |> Attempt.changeset(%{
      ticket_id: ticket.id,
      user_id: user.id
    })
    |> Repo.insert()
  end

  @spec get_or_create_attempt(%{ticket: Ticket.t(), user: User.t()}) ::
          {:ok, Attempt.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_attempt(%{ticket: ticket, user: user}) do
    case Repo.fetch_by(Attempt, ticket_id: ticket.id, user_id: user.id) do
      {:ok, attempt} -> {:ok, attempt}
      {:error, _reason} -> create_attempt(%{ticket: ticket, user: user})
    end
  end

  @spec list_attempts_for_ticket(String.t()) :: [Attempt.t()]
  def list_attempts_for_ticket(ticket_id) do
    Repo.all(
      from(a in Attempt,
        join: u in assoc(a, :user),
        where: a.ticket_id == ^ticket_id,
        order_by: [desc: a.inserted_at],
        select_merge: %{
          user: u
        }
      )
    )
  end

  def get_attempt_emoji(%Attempt{status: :inactive}), do: "🔴"
  def get_attempt_emoji(%Attempt{warnings_count: count}) when count > 0, do: "🟡"
  def get_attempt_emoji(%Attempt{status: :active}), do: "🟢"
end
