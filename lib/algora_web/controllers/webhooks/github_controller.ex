defmodule AlgoraWeb.Webhooks.GithubController do
  use AlgoraWeb, :controller

  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Github
  alias Algora.Github.Webhook
  alias Algora.Repo
  alias Algora.Workspace
  alias Algora.Workspace.CommandResponse
  alias Algora.Workspace.Installation

  require Logger

  # TODO: persist & alert about failed deliveries
  # TODO: auto-retry failed deliveries with exponential backoff

  def new(conn, payload) do
    with {:ok, webhook} <- Webhook.new(conn, payload),
         :ok <- process_delivery(webhook) do
      conn |> put_status(:accepted) |> json(%{status: "ok"})
    else
      {:error, :bot_event} ->
        conn |> put_status(:ok) |> json(%{status: "ok"})

      {:error, :missing_header} ->
        conn |> put_status(:bad_request) |> json(%{error: "Missing header"})

      {:error, :signature_mismatch} ->
        conn |> put_status(:unauthorized) |> json(%{error: "Signature mismatch"})

      {:error, reason} ->
        Logger.error("Error processing webhook: #{inspect(reason)}")
        conn |> put_status(:internal_server_error) |> json(%{error: "Internal server error"})

      error ->
        Logger.error("Error processing webhook: #{inspect(error)}")
        conn |> put_status(:internal_server_error) |> json(%{error: "Internal server error"})
    end
  rescue
    e ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))
      conn |> put_status(:internal_server_error) |> json(%{error: "Internal server error"})
  end

  def process_delivery(webhook) do
    with :ok <- ensure_human_author(webhook),
         {:ok, commands} <- process_commands(webhook),
         :ok <- process_event(webhook, commands) do
      Logger.debug("✅ #{inspect(webhook.event_action)}")
      :ok
    end
  end

  defp ensure_human_author(%Webhook{author: author}) do
    case author do
      %{"type" => "Bot"} -> {:error, :bot_event}
      _ -> :ok
    end
  end

  # TODO: cache installation tokens
  # TODO: check org permissions on algora
  defp get_permissions(%Webhook{payload: payload, author: author}) do
    with {:ok, access_token} <- Github.get_installation_token(payload["installation"]["id"]),
         {:ok, %{"permission" => permission}} <-
           Github.get_repository_permissions(
             access_token,
             payload["repository"]["owner"]["login"],
             payload["repository"]["name"],
             author["login"]
           ) do
      {:ok, permission}
    end
  end

  defp process_event(
         %Webhook{event_action: "pull_request.closed", payload: %{"pull_request" => %{"merged_at" => nil}}},
         _commands
       ) do
    :ok
  end

  defp process_event(%Webhook{event_action: "pull_request.closed", payload: payload}, _commands) do
    with {:ok, token} <- Github.get_installation_token(payload["installation"]["id"]),
         {:ok, source} <-
           Workspace.ensure_ticket(
             token,
             payload["repository"]["owner"]["login"],
             payload["repository"]["name"],
             payload["pull_request"]["number"]
           ) do
      claims =
        case Repo.one(
               from c in Claim,
                 join: s in assoc(c, :source),
                 join: u in assoc(c, :user),
                 where: s.id == ^source.id,
                 where: u.provider == "github",
                 where: u.provider_id == ^to_string(payload["pull_request"]["user"]["id"]),
                 order_by: [asc: c.inserted_at],
                 limit: 1
             ) do
          nil ->
            []

          %Claim{group_id: group_id} ->
            Repo.update_all(
              from(c in Claim, where: c.group_id == ^group_id),
              set: [status: :approved]
            )

            Repo.all(
              from c in Claim,
                join: t in assoc(c, :target),
                join: tr in assoc(t, :repository),
                join: tru in assoc(tr, :user),
                join: u in assoc(c, :user),
                where: c.group_id == ^group_id,
                order_by: [desc: c.group_share, asc: c.inserted_at],
                select_merge: %{
                  target: %{t | repository: %{tr | user: tru}},
                  user: u
                }
            )
        end

      if claims == [] do
        :ok
      else
        primary_claim = List.first(claims)

        installation =
          Repo.one(
            from i in Installation,
              where: i.provider == "github",
              where: i.provider_id == ^to_string(payload["installation"]["id"])
          )

        bounties =
          Repo.all(
            from(b in Bounty,
              join: t in assoc(b, :ticket),
              join: o in assoc(b, :owner),
              left_join: u in assoc(b, :creator),
              left_join: c in assoc(o, :customer),
              left_join: p in assoc(c, :default_payment_method),
              where: t.id == ^primary_claim.target_id,
              select_merge: %{owner: %{o | customer: %{default_payment_method: p}}, creator: u}
            )
          )

        autopayable_bounty =
          Enum.find(
            bounties,
            &(not is_nil(installation) and
                &1.owner.id == installation.connected_user_id and
                not is_nil(&1.owner.customer) and
                not is_nil(&1.owner.customer.default_payment_method))
          )

        autopay_result =
          if autopayable_bounty do
            with {:ok, invoice} <-
                   Bounties.create_invoice(
                     %{
                       owner: autopayable_bounty.owner,
                       amount: autopayable_bounty.amount
                     },
                     ticket_ref: %{
                       owner: payload["repository"]["owner"]["login"],
                       repo: payload["repository"]["name"],
                       number: payload["pull_request"]["number"]
                     },
                     bounty_id: autopayable_bounty.id,
                     claims: claims
                   ),
                 {:ok, _invoice} <-
                   Algora.Stripe.Invoice.pay(invoice, %{
                     payment_method: autopayable_bounty.owner.customer.default_payment_method.provider_id,
                     off_session: true
                   }) do
              Logger.info("Autopay successful (#{autopayable_bounty.owner.name} - #{autopayable_bounty.amount}).")
              :ok
            else
              {:error, reason} ->
                Logger.error(
                  "Autopay failed (#{autopayable_bounty.owner.name} - #{autopayable_bounty.amount}): #{inspect(reason)}"
                )

                :error
            end
          end

        unpaid_bounties =
          Enum.filter(
            bounties,
            &case autopay_result do
              :ok -> &1.id != autopayable_bounty.id
              _ -> true
            end
          )

        sponsors_to_notify =
          unpaid_bounties
          |> Enum.map(&(&1.creator || &1.owner))
          |> Enum.map_join(", ", &"@#{&1.provider_login}")

        if unpaid_bounties != [] do
          names =
            claims
            |> Enum.map(fn c -> "@#{c.user.provider_login}" end)
            |> Algora.Util.format_name_list()

          Github.create_issue_comment(
            token,
            primary_claim.target.repository.user.provider_login,
            primary_claim.target.repository.name,
            primary_claim.target.number,
            "🎉 The pull request of #{names} has been merged. You can visit [Algora](#{Claim.reward_url(primary_claim)}) to award the bounty." <>
              if(sponsors_to_notify == "", do: "", else: "\n\ncc #{sponsors_to_notify}")
          )
        end

        :ok
      end
    end
  end

  defp process_event(%Webhook{event_action: event_action, payload: payload}, commands)
       when event_action in ["pull_request.opened", "pull_request.reopened", "pull_request.edited"] do
    if Enum.any?(commands, &match?({:claim, _}, &1)) do
      :ok
    else
      source =
        Workspace.get_ticket(
          payload["repository"]["owner"]["login"],
          payload["repository"]["name"],
          payload["pull_request"]["number"]
        )

      case source do
        nil ->
          :ok

        source ->
          source.id
          |> Bounties.get_active_claims()
          |> Bounties.cancel_all_claims()
      end
    end
  end

  defp process_event(_webhook, _commands), do: :ok

  defp execute_command(%Webhook{event_action: event_action, payload: payload} = webhook, {:bounty, args})
       when event_action in ["issues.opened", "issues.edited", "issue_comment.created", "issue_comment.edited"] do
    amount = args[:amount]

    {command_source, command_id} =
      case webhook.event do
        "issue_comment" -> {:comment, payload["comment"]["id"]}
        "issues" -> {:ticket, payload["issue"]["id"]}
      end

    # TODO: perform compensating action if needed
    # ❌ comment1.created (:set) -> comment2.created (:increase) -> comment2.edited (:increase)
    # ✅ comment1.created (:set) -> comment2.created (:increase) -> comment2.edited (:decrease + :increase)
    strategy =
      case Repo.get_by(CommandResponse,
             provider: "github",
             provider_command_id: to_string(command_id),
             command_source: command_source
           ) do
        nil -> :increase
        _ -> :set
      end

    # TODO: community bounties?
    with {:ok, "admin"} <- get_permissions(webhook),
         {:ok, token} <- Github.get_installation_token(payload["installation"]["id"]),
         {:ok, installation} <-
           Workspace.fetch_installation_by(provider: "github", provider_id: to_string(payload["installation"]["id"])),
         {:ok, owner} <- Accounts.fetch_user_by(id: installation.connected_user_id),
         {:ok, creator} <- Workspace.ensure_user(token, payload["repository"]["owner"]["login"]) do
      Bounties.create_bounty(
        %{
          creator: creator,
          owner: owner,
          amount: amount,
          ticket_ref: %{
            owner: payload["repository"]["owner"]["login"],
            repo: payload["repository"]["name"],
            number: payload["issue"]["number"]
          }
        },
        strategy: strategy,
        installation_id: payload["installation"]["id"],
        command_id: command_id,
        command_source: command_source
      )
    else
      {:ok, _permission} ->
        {:error, :unauthorized}

      {:error, _reason} = error ->
        error
    end
  end

  defp execute_command(%Webhook{event_action: event_action, payload: payload} = webhook, {:tip, args})
       when event_action in ["issue_comment.created", "issue_comment.edited"] do
    amount = args[:amount]
    recipient = args[:recipient]

    # TODO: handle missing amount
    # TODO: handle missing recipient
    # TODO: handle tip to self
    # TODO: handle autopay with cooldown
    # TODO: community tips?
    case get_permissions(webhook) do
      {:ok, "admin"} ->
        Bounties.create_tip_intent(
          %{
            recipient: recipient,
            amount: amount,
            ticket_ref: %{
              owner: payload["repository"]["owner"]["login"],
              repo: payload["repository"]["name"],
              number: payload["issue"]["number"]
            }
          },
          installation_id: payload["installation"]["id"]
        )

      {:ok, _permission} ->
        {:error, :unauthorized}

      {:error, _reason} = error ->
        error
    end
  end

  defp execute_command(%Webhook{event_action: event_action, author: author, payload: payload}, {:attempt, args})
       when event_action in ["issue_comment.created", "issue_comment.edited"] do
    source_ticket_ref = %{
      owner: payload["repository"]["owner"]["login"],
      repo: payload["repository"]["name"],
      number: payload["issue"]["number"]
    }

    target_ticket_ref =
      %{
        owner: args[:ticket_ref][:owner] || source_ticket_ref.owner,
        repo: args[:ticket_ref][:repo] || source_ticket_ref.repo,
        number: args[:ticket_ref][:number]
      }

    with true <- source_ticket_ref == target_ticket_ref,
         {:ok, token} <- Github.get_installation_token(payload["installation"]["id"]),
         {:ok, ticket} <-
           Workspace.ensure_ticket(
             token,
             payload["repository"]["owner"]["login"],
             payload["repository"]["name"],
             payload["issue"]["number"]
           ),
         {:ok, user} <- Workspace.ensure_user(token, author["login"]),
         {:ok, attempt} <- Bounties.get_or_create_attempt(%{ticket: ticket, user: user}),
         {:ok, _} <- Bounties.refresh_bounty_response(token, target_ticket_ref, ticket) do
      {:ok, attempt}
    end
  end

  defp execute_command(%Webhook{event_action: event_action, author: author, payload: payload}, {:claim, args})
       when event_action in ["pull_request.opened", "pull_request.reopened", "pull_request.edited"] do
    source_ticket_ref = %{
      owner: payload["repository"]["owner"]["login"],
      repo: payload["repository"]["name"],
      number: payload["pull_request"]["number"]
    }

    target_ticket_ref =
      %{
        owner: args[:ticket_ref][:owner] || source_ticket_ref.owner,
        repo: args[:ticket_ref][:repo] || source_ticket_ref.repo,
        number: args[:ticket_ref][:number]
      }

    with {:ok, token} <- Github.get_installation_token(payload["installation"]["id"]),
         {:ok, user} <- Workspace.ensure_user(token, author["login"]) do
      Bounties.claim_bounty(
        %{
          user: user,
          coauthor_provider_logins: (args[:splits] || []) |> Enum.map(& &1[:recipient]) |> Enum.uniq(),
          target_ticket_ref: target_ticket_ref,
          source_ticket_ref: source_ticket_ref,
          status: if(payload["pull_request"]["merged_at"], do: :approved, else: :pending),
          type: :pull_request
        },
        installation_id: payload["installation"]["id"]
      )
    end
  end

  defp execute_command(_webhook, _command), do: {:ok, nil}

  def build_command({:claim, args}, commands) do
    splits = Keyword.get_values(commands, :split)
    {:claim, Keyword.put(args, :splits, splits)}
  end

  def build_command({:split, _args}, _commands), do: nil

  def build_command(command, _commands), do: command

  def build_commands(body) do
    case Github.Command.parse(body) do
      {:ok, commands} ->
        {:ok,
         commands
         |> Enum.map(&build_command(&1, commands))
         |> Enum.reject(&is_nil/1)
         # keep only the first claim command if multiple claims are present
         |> Enum.reduce([], fn
           {:claim, _} = claim, acc -> if Enum.any?(acc, &match?({:claim, _}, &1)), do: acc, else: [claim | acc]
           command, acc -> [command | acc]
         end)
         |> Enum.reverse()}

      {:error, reason} = error ->
        Logger.error("Error parsing commands: #{inspect(reason)}")
        error
    end
  end

  defp process_commands(%Webhook{body: body} = webhook) do
    with {:ok, commands} <- build_commands(body),
         :ok <- execute_commands(webhook, commands) do
      {:ok, commands}
    end
  end

  defp execute_commands(%Webhook{event_action: event_action, hook_id: hook_id} = webhook, commands) do
    Enum.reduce_while(commands, :ok, fn command, :ok ->
      case execute_command(webhook, command) do
        {:ok, _result} ->
          Logger.debug("✅ #{inspect(command)}")
          {:cont, :ok}

        error ->
          Logger.error("Command execution failed for #{event_action}(#{hook_id}): #{inspect(command)}: #{inspect(error)}")
          {:halt, error}
      end
    end)
  end
end
