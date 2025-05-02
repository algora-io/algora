defmodule Algora.Bounties do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.BotTemplates
  alias Algora.BotTemplates.BotTemplate
  alias Algora.Bounties.Attempt
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Jobs
  alias Algora.Bounties.LineItem
  alias Algora.Bounties.Tip
  alias Algora.Organizations.Member
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.PSP
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Ticket

  require Logger

  def base_query, do: Bounty

  @type criterion ::
          {:id, String.t()}
          | {:limit, non_neg_integer() | :infinity}
          | {:ticket_id, String.t()}
          | {:owner_id, String.t()}
          | {:status, :open | :paid}
          | {:tech_stack, [String.t()]}
          | {:before, %{inserted_at: DateTime.t(), id: String.t()}}
          | {:amount_gt, Money.t()}
          | {:current_user, User.t()}

  def broadcast do
    Phoenix.PubSub.broadcast(Algora.PubSub, "bounties:all", :bounties_updated)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Algora.PubSub, "bounties:all")
  end

  @spec do_create_bounty(%{
          creator: User.t(),
          owner: User.t(),
          amount: Money.t(),
          ticket: Ticket.t(),
          visibility: Bounty.visibility(),
          shared_with: [String.t()],
          hours_per_week: integer() | nil,
          hourly_rate: Money.t() | nil,
          contract_type: Bounty.contract_type() | nil
        }) ::
          {:ok, Bounty.t()} | {:error, atom()}
  defp do_create_bounty(%{creator: creator, owner: owner, amount: amount, ticket: ticket} = params) do
    changeset =
      Bounty.changeset(%Bounty{}, %{
        amount: amount,
        ticket_id: ticket.id,
        owner_id: owner.id,
        creator_id: creator.id,
        visibility: params[:visibility] || owner.bounty_mode,
        shared_with: params[:shared_with] || [],
        hours_per_week: params[:hours_per_week],
        hourly_rate: params[:hourly_rate],
        contract_type: params[:contract_type]
      })

    changeset
    |> Repo.insert_with_activity(%{
      type: :bounty_posted,
      notify_users: []
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

  def create_bounty(_params, opts \\ [])

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
            command_source: :ticket | :comment,
            visibility: Bounty.visibility() | nil,
            shared_with: [String.t()] | nil,
            hourly_rate: Money.t() | nil,
            hours_per_week: integer() | nil,
            contract_type: Bounty.contract_type() | nil
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
        opts
      ) do
    command_id = opts[:command_id]
    shared_with = opts[:shared_with] || []

    Repo.transact(fn ->
      with {:ok, %{installation_id: installation_id, token: token}} <-
             Workspace.resolve_installation_and_token(opts[:installation_id], repo_owner, creator),
           {:ok, ticket} <- Workspace.ensure_ticket(token, repo_owner, repo_name, number),
           existing = Repo.get_by(Bounty, owner_id: owner.id, ticket_id: ticket.id),
           {:ok, strategy} <- strategy_to_action(existing, opts[:strategy]),
           {:ok, bounty} <-
             (case strategy do
                :create ->
                  do_create_bounty(%{
                    creator: creator,
                    owner: owner,
                    amount: amount,
                    ticket: ticket,
                    visibility: opts[:visibility],
                    shared_with: shared_with,
                    hourly_rate: opts[:hourly_rate],
                    hours_per_week: opts[:hours_per_week],
                    contract_type: opts[:contract_type]
                  })

                :set ->
                  existing
                  |> Bounty.changeset(%{
                    amount: amount,
                    visibility: opts[:visibility],
                    shared_with: shared_with
                  })
                  # |> Activity.put_activity(%Bounty{}, %{type: :bounty_updated, notify_users: []})
                  |> Repo.update()

                :increase ->
                  existing
                  |> Bounty.changeset(%{
                    amount: Money.add!(existing.amount, amount),
                    visibility: opts[:visibility],
                    shared_with: shared_with
                  })
                  # |> Activity.put_activity(%Bounty{}, %{type: :bounty_updated, notify_users: []})
                  |> Repo.update()
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
        {:error, _reason} = error ->
          Algora.Admin.alert("Error creating bounty: #{inspect(error)}", :error)
          error
      end
    end)
  end

  @spec create_bounty(
          %{
            creator: User.t(),
            owner: User.t(),
            amount: Money.t(),
            title: String.t(),
            description: String.t()
          },
          opts :: [
            strategy: strategy(),
            visibility: Bounty.visibility() | nil,
            shared_with: [String.t()] | nil,
            hours_per_week: integer() | nil,
            hourly_rate: Money.t() | nil,
            contract_type: Bounty.contract_type() | nil
          ]
        ) ::
          {:ok, Bounty.t()} | {:error, atom()}
  def create_bounty(%{creator: creator, owner: owner, amount: amount, title: title, description: description}, opts) do
    shared_with = opts[:shared_with] || []

    Repo.transact(fn ->
      with {:ok, ticket} <-
             %Ticket{type: :issue}
             |> Ticket.changeset(%{title: title, description: description})
             |> Repo.insert(),
           {:ok, bounty} <-
             do_create_bounty(%{
               creator: creator,
               owner: owner,
               amount: amount,
               ticket: ticket,
               visibility: opts[:visibility],
               shared_with: shared_with,
               hours_per_week: opts[:hours_per_week],
               hourly_rate: opts[:hourly_rate],
               contract_type: opts[:contract_type]
             }),
           {:ok, _job} <- notify_bounty(%{owner: owner, bounty: bounty}) do
        broadcast()
        {:ok, bounty}
      else
        {:error, _reason} = error ->
          Algora.Admin.alert("Error creating bounty: #{inspect(error)}", :error)
          error
      end
    end)
  end

  defp claim_to_solution(claim) do
    %{
      type: :claim,
      started_at: claim.inserted_at,
      user: claim.user,
      group_id: claim.group_id,
      solution_id: "claim-#{claim.group_id}",
      indicator: "🟢",
      solution: "##{claim.source.number}"
    }
  end

  defp attempt_to_solution(attempt) do
    %{
      type: :attempt,
      started_at: attempt.inserted_at,
      user: attempt.user,
      group_id: attempt.id,
      solution_id: "attempt-#{attempt.id}",
      indicator: get_attempt_emoji(attempt),
      solution: "WIP"
    }
  end

  @spec get_response_body(
          bounties :: list(Bounty.t()),
          ticket_ref :: %{owner: String.t(), repo: String.t(), number: integer()},
          attempts :: list(Attempt.t()),
          claims :: list(Claim.t())
        ) :: String.t()
  def get_response_body(bounties, ticket_ref, attempts, claims) do
    custom_template =
      Repo.one(
        from bt in BotTemplate,
          where: bt.type == :bounty_created,
          where: bt.active == true,
          join: u in assoc(bt, :user),
          join: r in assoc(u, :repositories),
          join: t in assoc(r, :tickets),
          where: t.id == ^List.first(bounties).ticket_id
      )

    prize_pool = format_prize_pool(bounties)
    attempts_table = format_attempts_table(attempts, claims)

    template =
      if custom_template do
        custom_template.template
      else
        BotTemplates.get_default_template(:bounty_created)
      end

    template
    |> String.replace("${PRIZE_POOL}", prize_pool)
    |> String.replace("${ISSUE_NUMBER}", to_string(ticket_ref[:number]))
    |> String.replace("${REPO_FULL_NAME}", "#{ticket_ref[:owner]}/#{ticket_ref[:repo]}")
    |> String.replace("${ATTEMPTS}", attempts_table)
    |> String.replace("${FUND_URL}", AlgoraWeb.Endpoint.url())
    |> String.replace("${TWEET_URL}", generate_tweet_url(bounties, ticket_ref))
    |> String.replace("${ADDITIONAL_OPPORTUNITIES}", "")
    |> String.trim()
  end

  defp generate_tweet_url(bounties, ticket_ref) do
    total_amount = Enum.reduce(bounties, Money.new(0, :USD), &Money.add!(&2, &1.amount))

    text =
      "#{Money.to_string!(total_amount, no_fraction_if_integer: true)} bounty! 💎 https://github.com/#{ticket_ref[:owner]}/#{ticket_ref[:repo]}/issues/#{ticket_ref[:number]}"

    uri = URI.parse("https://twitter.com/intent/tweet")

    query =
      URI.encode_query(%{
        "text" => text,
        "related" => "algoraio"
      })

    URI.to_string(%{uri | query: query})
  end

  defp format_prize_pool(bounties) do
    Enum.map_join(bounties, "\n", fn bounty ->
      "## 💎 #{Money.to_string!(bounty.amount, no_fraction_if_integer: true)} bounty [• #{bounty.owner.name}](#{User.url(bounty.owner)})"
    end)
  end

  defp format_attempts_table(attempts, claims) do
    solutions =
      []
      |> Enum.concat(Enum.map(claims, &claim_to_solution/1))
      |> Enum.concat(Enum.map(attempts, &attempt_to_solution/1))
      |> Enum.group_by(& &1.user.id)
      |> Enum.map(fn {_user_id, solutions} ->
        started_at = Enum.min_by(solutions, & &1.started_at).started_at
        solution = Enum.find(solutions, &(&1.type == :claim)) || List.first(solutions)
        %{solution | started_at: started_at}
      end)
      |> Enum.group_by(& &1.solution_id)
      |> Enum.sort_by(fn {_solution_id, solutions} -> Enum.min_by(solutions, & &1.started_at).started_at end)
      |> Enum.map(fn {_solution_id, solutions} ->
        primary_solution = Enum.min_by(solutions, & &1.started_at)
        timestamp = Calendar.strftime(primary_solution.started_at, "%b %d, %Y, %I:%M:%S %p")

        users =
          solutions
          |> Enum.sort_by(& &1.started_at)
          |> Enum.map(&"@#{&1.user.provider_login}")
          |> Util.format_name_list()

        actions =
          if primary_solution.type == :claim do
            "[Reward](#{AlgoraWeb.Endpoint.url()}/claims/#{primary_solution.group_id})"
          else
            ""
          end

        "| #{primary_solution.indicator} #{users} | #{timestamp} | #{primary_solution.solution} | #{actions} |"
      end)

    if solutions == [] do
      ""
    else
      """

      | Attempt | Started (UTC) | Solution | Actions |
      | --- | --- | --- | --- |
      #{Enum.join(solutions, "\n")}
      """
    end
  end

  def refresh_bounty_response(token, ticket_ref, ticket) do
    bounties = list_bounties(ticket_id: ticket.id)
    attempts = list_attempts_for_ticket(ticket.id)
    claims = list_claims([ticket.id])
    body = get_response_body(bounties, ticket_ref, attempts, claims)

    Workspace.refresh_command_response(%{
      token: token,
      ticket_ref: ticket_ref,
      ticket: ticket,
      body: body,
      command_type: :bounty
    })
  end

  def try_refresh_bounty_response(token, ticket_ref, ticket) do
    case refresh_bounty_response(token, ticket_ref, ticket) do
      {:ok, response} ->
        {:ok, response}

      {:error, _} ->
        Logger.warning(
          "Failed to refresh bounty response for #{ticket_ref[:owner]}/#{ticket_ref[:repo]}##{ticket_ref[:number]}"
        )

        {:ok, nil}
    end
  end

  def notify_bounty(bounty, opts \\ [])

  @spec notify_bounty(
          %{
            owner: User.t(),
            bounty: Bounty.t(),
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}
          },
          opts :: [installation_id: integer(), command_id: integer(), command_source: :ticket | :comment]
        ) ::
          {:ok, Oban.Job.t()} | {:error, atom()}
  def notify_bounty(%{owner: owner, bounty: bounty, ticket_ref: ticket_ref}, opts) do
    %{
      owner_login: owner.provider_login,
      amount: Money.to_string!(bounty.amount, no_fraction_if_integer: true),
      ticket_ref: %{owner: ticket_ref.owner, repo: ticket_ref.repo, number: ticket_ref.number},
      installation_id: opts[:installation_id],
      command_id: opts[:command_id],
      command_source: opts[:command_source],
      bounty_id: bounty.id,
      visibility: bounty.visibility,
      shared_with: bounty.shared_with
    }
    |> Jobs.NotifyBounty.new()
    |> Oban.insert()
  end

  @spec notify_bounty(%{owner: User.t(), bounty: Bounty.t()}, opts :: []) ::
          {:ok, nil} | {:error, atom()}
  def notify_bounty(%{owner: _owner, bounty: bounty}, _opts) do
    Algora.Admin.alert("Notify bounty: #{inspect(bounty)}", :error)
    {:ok, nil}
  end

  @spec do_claim_bounty(%{
          provider_login: String.t(),
          token: String.t(),
          target: Ticket.t(),
          source: Ticket.t(),
          group_id: String.t() | nil,
          group_share: Decimal.t(),
          status: Claim.status(),
          type: Claim.type()
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
    case Workspace.ensure_user(token, provider_login) do
      {:ok, user} ->
        activity_attrs = %{type: :claim_submitted, notify_users: []}

        claim_attrs = %{
          target_id: target.id,
          source_id: source.id,
          user_id: user.id,
          type: type,
          status: status,
          url: source.url,
          group_id: group_id,
          group_share: group_share
        }

        # Try to find existing claim
        existing_claim =
          Repo.get_by(Claim,
            target_id: target.id,
            source_id: source.id,
            user_id: user.id
          )

        case existing_claim do
          nil ->
            # Create new claim
            %Claim{}
            |> Claim.changeset(claim_attrs)
            |> Repo.insert_with_activity(activity_attrs)

          claim ->
            claim
            |> Claim.changeset(claim_attrs)
            |> Repo.update_with_activity(activity_attrs)
        end

      {:error, _reason} = error ->
        error
    end
  end

  @spec do_claim_bounties(%{
          provider_logins: [String.t()],
          token: String.t(),
          target: Ticket.t(),
          source: Ticket.t(),
          status: Claim.status(),
          type: Claim.type()
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
            status: Claim.status(),
            type: Claim.type()
          },
          opts :: [installation_id: integer()]
        ) ::
          {:ok, [Claim.t()]} | {:error, atom()}
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
    Repo.transact(fn ->
      with {:ok, %{installation_id: installation_id, token: token}} <-
             Workspace.resolve_installation_and_token(opts[:installation_id], source_repo_owner, user),
           {:ok, target} <- Workspace.ensure_ticket(token, target_repo_owner, target_repo_name, target_number),
           {:ok, source} <- Workspace.ensure_ticket(token, source_repo_owner, source_repo_name, source_number) do
        # Get all active claims for this PR
        active_claims = get_active_claims(source.id)
        requested_participants = [user.provider_login | coauthor_provider_logins]

        cond do
          # Case 1: Target changed - cancel all claims and create new ones
          target_changed?(active_claims, target.id) ->
            with :ok <- cancel_all_claims(active_claims) do
              create_new_claims(token, source, target, requested_participants, status, type, installation_id)
            end

          # Case 3: Participants changed - cancel old claims and create new ones
          participants_changed?(active_claims, requested_participants) ->
            with :ok <- cancel_all_claims(active_claims) do
              create_new_claims(token, source, target, requested_participants, status, type, installation_id)
            end

          # Case 4: No existing claims - create new ones
          Enum.empty?(active_claims) ->
            create_new_claims(token, source, target, requested_participants, status, type, installation_id)

          # Case 5: No changes needed
          true ->
            {:ok, active_claims}
        end
      else
        {:error, _reason} = error -> error
      end
    end)
  end

  def get_active_claims(source_id) do
    Repo.all(
      from c in Claim,
        where: c.source_id == ^source_id,
        where: c.status == :pending,
        preload: [:user]
    )
  end

  defp target_changed?(claims, target_id) do
    Enum.any?(claims, fn claim -> claim.target_id != target_id end)
  end

  defp participants_changed?(claims, requested_participants) do
    current_participants =
      claims
      |> Enum.map(& &1.user.provider_login)
      |> Enum.sort()

    requested_participants
    |> Enum.sort()
    |> Kernel.!=(current_participants)
  end

  def cancel_all_claims(claims) do
    Enum.reduce_while(claims, :ok, fn claim, :ok ->
      case claim
           |> Claim.changeset(%{status: :cancelled, group_share: Decimal.new(0)})
           |> Repo.update() do
        {:ok, _} -> {:cont, :ok}
        error -> error
      end
    end)
  end

  defp create_new_claims(token, source, target, participants, status, type, installation_id) do
    with {:ok, [claim | _] = claims} <-
           do_claim_bounties(%{
             provider_logins: participants,
             token: token,
             target: target,
             source: source,
             status: status,
             type: type
           }),
         {:ok, _job} <- notify_claim(%{claim: claim}, installation_id: installation_id) do
      broadcast()
      {:ok, claims}
    end
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

  @spec build_tip_intent(
          %{
            recipient: String.t() | nil,
            amount: Money.t() | nil,
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}
          },
          opts :: [installation_id: integer()]
        ) ::
          Oban.Job.changeset()
  def build_tip_intent(
        %{recipient: recipient, amount: amount, ticket_ref: %{owner: owner, repo: repo, number: number}},
        opts \\ []
      ) do
    body =
      cond do
        recipient == nil ->
          "Please specify a recipient to tip (e.g. `/tip $#{Money.to_decimal(amount)} @jsmith`)"

        amount == nil ->
          "Please specify an amount to tip (e.g. `/tip $100 @#{recipient}`)"

        true ->
          installation =
            case opts[:installation_id] do
              nil -> nil
              installation_id -> Repo.get_by(Installation, provider: "github", provider_id: to_string(installation_id))
            end

          query =
            URI.encode_query(
              amount: Money.to_decimal(amount),
              recipient: recipient,
              owner: owner,
              repo: repo,
              number: number,
              org_id: if(installation, do: installation.connected_user_id)
            )

          url = AlgoraWeb.Endpoint.url() <> "/tip" <> "?" <> query

          "Please visit [Algora](#{url}) to complete your tip via Stripe."
      end

    Jobs.NotifyTipIntent.new(%{
      body: body,
      ticket_ref: %{owner: owner, repo: repo, number: number},
      installation_id: opts[:installation_id]
    })
  end

  @spec create_tip_intent(
          params :: %{
            recipient: String.t() | nil,
            amount: Money.t() | nil,
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}
          },
          opts :: [installation_id: integer()]
        ) ::
          {:ok, Oban.Job.t()} | {:error, atom()}
  def create_tip_intent(params, opts \\ []) do
    params
    |> build_tip_intent(opts)
    |> Oban.insert()
  end

  @spec create_tip(
          %{creator: User.t(), owner: User.t(), recipient: User.t(), amount: Money.t()},
          opts :: [ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}, installation_id: integer()]
        ) ::
          {:ok, String.t()} | {:error, atom()}
  def create_tip(%{creator: creator, owner: owner, recipient: recipient, amount: amount}, opts \\ []) do
    Repo.transact(fn ->
      case do_create_tip(%{creator: creator, owner: owner, recipient: recipient, amount: amount}, opts) do
        {:ok, tip} ->
          create_payment_session(
            %{owner: owner, amount: amount, description: "Tip payment for OSS contributions"},
            ticket_ref: opts[:ticket_ref],
            tip_id: tip.id,
            recipient: recipient
          )

        {:error, reason} ->
          Algora.Admin.alert("Error creating tip: #{inspect(reason)}", :error)
          {:error, reason}
      end
    end)
  end

  @spec do_create_tip(
          %{creator: User.t(), owner: User.t(), recipient: User.t(), amount: Money.t()},
          opts :: [ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()}, installation_id: integer()]
        ) ::
          {:ok, Tip.t()} | {:error, atom()}
  def do_create_tip(%{creator: creator, owner: owner, recipient: recipient, amount: amount}, opts \\ []) do
    ticket_res =
      if ticket_ref = opts[:ticket_ref] do
        with {:ok, %{token: token}} <-
               Workspace.resolve_installation_and_token(opts[:installation_id], ticket_ref[:owner], creator) do
          Workspace.ensure_ticket(token, ticket_ref[:owner], ticket_ref[:repo], ticket_ref[:number])
        end
      else
        {:ok, nil}
      end

    with {:ok, ticket} <- ticket_res do
      %Tip{}
      |> Tip.changeset(%{
        amount: amount,
        owner_id: owner.id,
        creator_id: creator.id,
        recipient_id: recipient.id,
        ticket_id: if(ticket, do: ticket.id)
      })
      |> Repo.insert()
    end
  end

  @spec reward_bounty(
          %{
            owner: User.t(),
            amount: Money.t(),
            bounty: Bounty.t(),
            claims: [Claim.t()]
          },
          opts :: [
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
            recipient: User.t(),
            success_url: String.t(),
            cancel_url: String.t()
          ]
        ) ::
          {:ok, String.t()} | {:error, atom()}
  def reward_bounty(%{owner: owner, amount: amount, bounty: bounty, claims: claims}, opts \\ []) do
    create_payment_session(
      %{owner: owner, amount: amount, description: "Bounty payment for OSS contributions"},
      ticket_ref: opts[:ticket_ref],
      bounty: bounty,
      claims: claims,
      recipient: opts[:recipient],
      success_url: opts[:success_url],
      cancel_url: opts[:cancel_url]
    )
  end

  @spec authorize_payment(
          %{
            owner: User.t(),
            amount: Money.t(),
            bounty: Bounty.t(),
            claims: [Claim.t()]
          },
          opts :: [
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
            recipient: User.t(),
            success_url: String.t(),
            cancel_url: String.t()
          ]
        ) ::
          {:ok, String.t()} | {:error, atom()}
  def authorize_payment(%{owner: owner, amount: amount, bounty: bounty, claims: claims}, opts \\ []) do
    create_payment_session(
      %{owner: owner, amount: amount, description: "Bounty payment for OSS contributions"},
      ticket_ref: opts[:ticket_ref],
      bounty: bounty,
      claims: claims,
      recipient: opts[:recipient],
      capture_method: :manual,
      success_url: opts[:success_url],
      cancel_url: opts[:cancel_url]
    )
  end

  @spec generate_line_items(
          %{owner: User.t(), amount: Money.t()},
          opts :: [
            bounty: Bounty.t(),
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
            claims: [Claim.t()],
            recipient: User.t()
          ]
        ) ::
          [LineItem.t()]
  def generate_line_items(%{owner: owner, amount: amount}, opts \\ []) do
    bounty = opts[:bounty]
    ticket_ref = opts[:ticket_ref]
    recipient = opts[:recipient]
    claims = opts[:claims] || []

    description = if(ticket_ref, do: "#{ticket_ref[:repo]}##{ticket_ref[:number]}")

    platform_fee_pct =
      if bounty && Date.before?(bounty.inserted_at, ~D[2025-04-16]) && is_nil(bounty.contract_type) do
        Decimal.div(owner.fee_pct_prev, 100)
      else
        Decimal.div(owner.fee_pct, 100)
      end

    transaction_fee_pct = Payments.get_transaction_fee_pct()

    case opts[:bounty] do
      %{contract_type: :marketplace} ->
        [
          %LineItem{
            amount: amount,
            title: "Contract payment - @#{recipient.provider_login}",
            description: "(includes all platform and payment processing fees)",
            image: recipient.avatar_url,
            type: :payout
          }
        ]

      _ ->
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
          Enum.map(claims, fn claim ->
            %LineItem{
              # TODO: ensure shares are normalized
              amount: Money.mult!(amount, claim.group_share),
              title: "Payment to @#{claim.user.provider_login}",
              description: description,
              image: claim.user.avatar_url,
              type: :payout
            }
          end)
        end ++
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
  end

  def final_contract_amount(:marketplace, amount), do: amount

  def final_contract_amount(:bring_your_own, amount), do: Money.mult!(amount, Decimal.new("1.13"))

  @spec create_payment_session(
          %{owner: User.t(), amount: Money.t(), description: String.t()},
          opts :: [
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
            tip_id: String.t(),
            bounty: Bounty.t(),
            claims: [Claim.t()],
            recipient: User.t(),
            capture_method: :automatic | :automatic_async | :manual,
            success_url: String.t(),
            cancel_url: String.t()
          ]
        ) ::
          {:ok, String.t()} | {:error, atom()}
  def create_payment_session(%{owner: owner, amount: amount, description: description}, opts \\ []) do
    tx_group_id = Nanoid.generate()

    line_items =
      generate_line_items(%{owner: owner, amount: amount},
        ticket_ref: opts[:ticket_ref],
        recipient: opts[:recipient],
        claims: opts[:claims],
        bounty: opts[:bounty]
      )

    payment_intent_data = %{
      description: description,
      metadata: %{"version" => Payments.metadata_version(), "group_id" => tx_group_id}
    }

    {payment_intent_data, session_opts} =
      if capture_method = opts[:capture_method] do
        {Map.put(payment_intent_data, :capture_method, capture_method),
         [success_url: opts[:success_url], cancel_url: opts[:cancel_url]]}
      else
        {payment_intent_data, []}
      end

    gross_amount = LineItem.gross_amount(line_items)

    bounty_id = if bounty = opts[:bounty], do: bounty.id

    Repo.transact(fn ->
      with {:ok, _charge} <-
             initialize_charge(%{
               id: Nanoid.generate(),
               user_id: owner.id,
               bounty_id: bounty_id,
               gross_amount: gross_amount,
               net_amount: amount,
               total_fee: Money.sub!(gross_amount, amount),
               line_items: line_items,
               group_id: tx_group_id,
               idempotency_key: "session-#{Nanoid.generate()}"
             }),
           {:ok, _transactions} <-
             create_transaction_pairs(%{
               claims: opts[:claims] || [],
               tip_id: opts[:tip_id],
               recipient_id: if(opts[:recipient], do: opts[:recipient].id),
               bounty_id: bounty_id,
               claim_id: nil,
               amount: amount,
               creator_id: owner.id,
               group_id: tx_group_id
             }),
           {:ok, session} <-
             Payments.create_stripe_session(
               owner,
               Enum.map(line_items, &LineItem.to_stripe/1),
               payment_intent_data,
               session_opts
             ) do
        {:ok, session.url}
      end
    end)
  end

  @spec create_invoice(
          %{owner: User.t(), amount: Money.t(), idempotency_key: String.t()},
          opts :: [
            ticket_ref: %{owner: String.t(), repo: String.t(), number: integer()},
            tip_id: String.t(),
            bounty: Bounty.t(),
            claims: [Claim.t()],
            recipient: User.t()
          ]
        ) ::
          {:ok, PSP.invoice()} | {:error, atom()}
  def create_invoice(%{owner: owner, amount: amount, idempotency_key: idempotency_key}, opts \\ []) do
    tx_group_id = Nanoid.generate()

    line_items =
      generate_line_items(%{owner: owner, amount: amount},
        ticket_ref: opts[:ticket_ref],
        recipient: opts[:recipient],
        claims: opts[:claims],
        bounty: opts[:bounty]
      )

    gross_amount = LineItem.gross_amount(line_items)

    bounty_id = if bounty = opts[:bounty], do: bounty.id

    Repo.transact(fn ->
      with {:ok, _charge} <-
             initialize_charge(%{
               id: Nanoid.generate(),
               user_id: owner.id,
               bounty_id: bounty_id,
               gross_amount: gross_amount,
               net_amount: amount,
               total_fee: Money.sub!(gross_amount, amount),
               line_items: line_items,
               group_id: tx_group_id,
               idempotency_key: idempotency_key
             }),
           {:ok, _transactions} <-
             create_transaction_pairs(%{
               claims: opts[:claims] || [],
               tip_id: opts[:tip_id],
               recipient_id: if(opts[:recipient], do: opts[:recipient].id),
               bounty_id: bounty_id,
               claim_id: nil,
               amount: amount,
               creator_id: owner.id,
               group_id: tx_group_id
             }),
           {:ok, customer} <- Payments.fetch_or_create_customer(owner),
           {:ok, invoice} <-
             PSP.Invoice.create(
               %{
                 auto_advance: false,
                 customer: customer.provider_id,
                 metadata: %{"version" => Payments.metadata_version(), "group_id" => tx_group_id}
               },
               %{idempotency_key: idempotency_key}
             ),
           {:ok, _line_items} <-
             line_items
             |> Enum.map(&LineItem.to_invoice_item(&1, invoice, customer))
             |> Enum.with_index()
             |> Enum.reduce_while({:ok, []}, fn {params, index}, {:ok, acc} ->
               case PSP.Invoiceitem.create(params, %{idempotency_key: "#{idempotency_key}-#{index}"}) do
                 {:ok, item} -> {:cont, {:ok, [item | acc]}}
                 {:error, error} -> {:halt, {:error, error}}
               end
             end) do
        {:ok, invoice}
      end
    end)
  end

  defp initialize_charge(
         %{
           id: id,
           user_id: user_id,
           gross_amount: gross_amount,
           net_amount: net_amount,
           total_fee: total_fee,
           line_items: line_items,
           group_id: group_id,
           idempotency_key: idempotency_key
         } = params
       ) do
    %Transaction{}
    |> change(%{
      id: id,
      provider: "stripe",
      type: :charge,
      status: :initialized,
      user_id: user_id,
      bounty_id: params[:bounty_id],
      gross_amount: gross_amount,
      net_amount: net_amount,
      total_fee: total_fee,
      line_items: Util.normalize_struct(line_items),
      group_id: group_id,
      idempotency_key: idempotency_key
    })
    |> Algora.Validations.validate_positive(:gross_amount)
    |> Algora.Validations.validate_positive(:net_amount)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:idempotency_key])
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
      {:id, id}, query ->
        from([b] in query, where: b.id == ^id)

      {:limit, :infinity}, query ->
        query

      {:limit, limit}, query ->
        from([b] in query, limit: ^limit)

      {:ticket_id, ticket_id}, query ->
        from([b] in query, where: b.ticket_id == ^ticket_id)

      {:owner_id, owner_id}, query ->
        from([b, r: r] in query, where: b.owner_id == ^owner_id or r.user_id == ^owner_id)

      {:owner_handle, owner_handle}, query ->
        from([b, o: o, ro: ro] in query, where: o.handle == ^owner_handle or ro.handle == ^owner_handle)

      {:status, status}, query ->
        query = where(query, [b], b.status == ^status)

        case status do
          :open ->
            query = where(query, [t: t], t.state == :open)

            query =
              case criteria[:current_user] do
                nil ->
                  where(query, [b], b.visibility != :exclusive)

                user ->
                  where(
                    query,
                    [b],
                    b.visibility != :exclusive or
                      fragment(
                        "? && ARRAY[?, ?, ?]::citext[]",
                        b.shared_with,
                        ^user.id,
                        ^user.email,
                        ^to_string(user.provider_id)
                      ) or
                      fragment(
                        "EXISTS (SELECT 1 FROM members m WHERE m.user_id = ? AND m.org_id = ? AND m.role = ANY(?))",
                        ^user.id,
                        b.owner_id,
                        ^["admin", "mod"]
                      )
                  )
              end

            query =
              case criteria[:owner_id] || criteria[:owner_handle] do
                nil ->
                  where(query, [b, o: o], (b.visibility == :public and o.featured == true) or b.visibility == :exclusive)

                _org_id ->
                  query
              end

            query

          _ ->
            query
        end

      {:before, %{inserted_at: inserted_at, id: id}}, query ->
        from([b] in query,
          where: {b.inserted_at, b.id} < {^inserted_at, ^id}
        )

      {:tech_stack, []}, query ->
        query

      {:tech_stack, tech_stack}, query ->
        from([b, r: r] in query,
          where:
            b.visibility == :exclusive or fragment("? && ?::citext[]", r.tech_stack, ^tech_stack) or r.tech_stack == ^[]
        )

      {:amount_gt, min_amount}, query ->
        from([b] in query,
          where:
            b.visibility == :exclusive or
              fragment(
                "?::money_with_currency >= (?, ?)::money_with_currency",
                b.amount,
                ^to_string(min_amount.currency),
                ^min_amount.amount
              )
        )

      _, query ->
        query
    end)
  end

  def list_bounties_query(base_query, criteria \\ []) do
    criteria = Keyword.merge([order: :date, limit: 10], criteria)

    base_bounties = select(base_query, [b], b.id)

    from(b in Bounty)
    |> join(:inner, [b], bb in subquery(base_bounties), on: b.id == bb.id)
    |> join(:inner, [b], t in assoc(b, :ticket), as: :t)
    |> join(:inner, [b], o in assoc(b, :owner), as: :o)
    |> join(:inner, [t: t], r in assoc(t, :repository), as: :r)
    |> join(:left, [r: r], ro in assoc(r, :user), as: :ro)
    |> where([b], not is_nil(b.amount))
    |> where([b], b.status != :cancelled)
    |> apply_criteria(criteria)
  end

  def list_bounties_with(base_query, criteria \\ []) do
    base_query
    |> list_bounties_query(criteria)
    # TODO: sort by b.paid_at if criteria[:status] == :paid
    |> order_by([b], desc: b.inserted_at, desc: b.id)
    |> select([b, o: o, t: t, ro: ro, r: r], %{
      id: b.id,
      inserted_at: b.inserted_at,
      amount: b.amount,
      status: b.status,
      owner: %{
        id: o.id,
        inserted_at: o.inserted_at,
        name: o.name,
        handle: o.handle,
        provider_login: o.provider_login,
        avatar_url: o.avatar_url,
        tech_stack: o.tech_stack
      },
      ticket_id: t.id,
      ticket: %{
        id: t.id,
        title: t.title,
        number: t.number,
        url: t.url,
        description: t.description
      },
      repository: %{
        id: r.id,
        name: r.name,
        owner: %{
          id: ro.id,
          name: ro.name,
          handle: ro.handle,
          provider_login: ro.provider_login,
          avatar_url: ro.avatar_url
        }
      }
    })
    |> Repo.all()
  end

  def list_tech(criteria \\ []) do
    base_query()
    |> list_bounties_query(Keyword.put(criteria, :limit, :infinity))
    |> where([b, r: r], not is_nil(r.tech_stack))
    |> join(:cross_lateral, [b, r: r], tech in fragment("SELECT UNNEST(?) as tech", r.tech_stack), as: :tech)
    |> group_by([b, r: r, tech: tech], fragment("tech"))
    |> select([b, r: r, tech: tech], {fragment("tech"), count(fragment("tech"))})
    |> order_by([b, r: r, tech: tech], desc: count(fragment("tech")))
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
        where: c.status != :cancelled,
        select_merge: %{user: user, source: s}
    )
  end

  def list_bounties(criteria \\ []) do
    list_bounties_with(base_query(), criteria)
  end

  def fetch_stats(opts) do
    zero_money = Money.zero(:USD, no_fraction_if_integer: true)

    open_bounties_query =
      from b in Bounty,
        join: t in assoc(b, :ticket),
        left_join: r in assoc(t, :repository),
        where: b.owner_id == ^opts[:org_id] or r.user_id == ^opts[:org_id],
        where: b.status == :open,
        where: b.status != :cancelled,
        where: not is_nil(b.amount),
        where: t.state == :open

    open_bounties_query =
      case(opts[:current_user]) do
        nil ->
          where(open_bounties_query, [b], b.visibility != :exclusive)

        user ->
          where(
            open_bounties_query,
            [b],
            b.visibility != :exclusive or
              fragment(
                "? && ARRAY[?, ?, ?]::citext[]",
                b.shared_with,
                ^user.id,
                ^user.email,
                ^to_string(user.provider_id)
              ) or
              fragment(
                "EXISTS (SELECT 1 FROM members m WHERE m.user_id = ? AND m.org_id = ? AND m.role = ANY(?))",
                ^user.id,
                b.owner_id,
                ^["admin", "mod"]
              )
          )
      end

    rewards_query =
      from tx in Transaction,
        where: tx.type == :credit,
        where: tx.status == :succeeded,
        join: ltx in assoc(tx, :linked_transaction),
        left_join: b in assoc(tx, :bounty),
        as: :b,
        left_join: t in assoc(b, :ticket),
        left_join: r in assoc(t, :repository),
        where: ltx.type == :debit,
        where: ltx.status == :succeeded,
        where: ltx.user_id == ^opts[:org_id] or r.user_id == ^opts[:org_id]

    rewarded_bounties_query =
      rewards_query
      |> where([t], not is_nil(t.bounty_id))
      |> distinct([:user_id, :bounty_id])

    rewarded_tips_query =
      rewards_query
      |> where([t], not is_nil(t.tip_id))
      |> distinct([:user_id, :tip_id])

    rewarded_bonuses_query =
      rewards_query
      |> where([t, b: b], t.net_amount > b.amount)
      |> distinct([:user_id, :bounty_id])

    rewarded_contracts_query =
      rewards_query
      |> where([t], not is_nil(t.contract_id))
      |> distinct([:user_id, :contract_id])

    rewarded_users_query =
      rewards_query
      |> distinct(true)
      |> select([:user_id])

    rewarded_users_diff_query =
      from t in rewarded_users_query,
        where: t.succeeded_at >= fragment("NOW() - INTERVAL '1 month'"),
        except_all: ^from(t in rewarded_users_query, where: t.succeeded_at < fragment("NOW() - INTERVAL '1 month'"))

    members_query = Member.filter_by_org_id(Member, opts[:org_id])
    open_bounties = Repo.aggregate(open_bounties_query, :count, :id)
    open_bounties_amount = Repo.aggregate(open_bounties_query, :sum, :amount) || zero_money
    total_awarded_amount = Repo.aggregate(rewards_query, :sum, :net_amount) || zero_money
    rewarded_bounties_count = Repo.aggregate(rewarded_bounties_query, :count, :id)
    rewarded_tips_count = Repo.aggregate(rewarded_tips_query, :count, :id)
    rewarded_bonuses_count = Repo.aggregate(rewarded_bonuses_query, :count, :id)
    rewarded_contracts_count = Repo.aggregate(rewarded_contracts_query, :count, :id)
    solvers_diff = Repo.aggregate(rewarded_users_diff_query, :count, :user_id)
    solvers_count = Repo.aggregate(rewarded_users_query, :count, :user_id)
    members_count = Repo.aggregate(members_query, :count, :id)

    %{
      open_bounties_amount: open_bounties_amount,
      open_bounties_count: open_bounties,
      total_awarded_amount: total_awarded_amount,
      rewarded_bounties_count: rewarded_bounties_count,
      rewarded_tips_count: rewarded_tips_count + rewarded_bonuses_count,
      rewarded_contracts_count: rewarded_contracts_count,
      solvers_count: solvers_count,
      solvers_diff: solvers_diff,
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
