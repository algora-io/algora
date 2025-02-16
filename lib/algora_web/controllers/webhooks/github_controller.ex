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

  def new(conn, params) do
    with {:ok, %{event: event} = webhook} <- Webhook.new(conn),
         :ok <- ensure_human_author(webhook, params),
         author = get_author(event, params),
         body = get_body(event, params),
         event_action = event <> "." <> params["action"],
         {:ok, _} <- process_commands(webhook, event_action, author, body, params),
         :ok <- process_event(event_action, params) do
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
    end
  rescue
    e ->
      Logger.error("Unexpected error: #{inspect(e)}")
      conn |> put_status(:internal_server_error) |> json(%{error: "Internal server error"})
  end

  defp ensure_human_author(%Webhook{event: event}, params) do
    case get_author(event, params) do
      %{"type" => "Bot"} -> {:error, :bot_event}
      _ -> :ok
    end
  end

  # TODO: cache installation tokens
  # TODO: check org permissions on algora
  defp get_permissions(author, %{"repository" => repository, "installation" => installation}) do
    with {:ok, access_token} <- Github.get_installation_token(installation["id"]),
         {:ok, %{"permission" => permission}} <-
           Github.get_repository_permissions(
             access_token,
             repository["owner"]["login"],
             repository["name"],
             author["login"]
           ) do
      {:ok, permission}
    end
  end

  defp get_permissions(_author, _params), do: {:error, :invalid_params}

  defp process_event(event_action, params) when event_action in ["pull_request.closed"] do
    %{"repository" => repository, "pull_request" => pull_request, "installation" => installation} = params

    if pull_request["merged_at"] do
      with {:ok, token} <- Github.get_installation_token(installation["id"]),
           {:ok, source} <-
             Workspace.ensure_ticket(token, repository["owner"]["login"], repository["name"], pull_request["number"]) do
        claims_query =
          from c in Claim,
            join: s in assoc(c, :source),
            join: t in assoc(c, :target),
            join: tr in assoc(t, :repository),
            join: tru in assoc(tr, :user),
            join: u in assoc(c, :user),
            where: s.id == ^source.id,
            where: u.provider == "github",
            where: u.provider_id == ^to_string(pull_request["user"]["id"])

        Repo.update_all(claims_query, set: [status: :approved])

        # TODO: handle multi claims
        # TODO: handle splits
        claim =
          claims_query
          |> order_by([c], asc: c.inserted_at)
          |> limit(1)
          |> select_merge([c, s, t, tr, tru, u], %{
            source: s,
            target: %{t | repository: %{tr | user: tru}},
            user: u
          })
          |> Repo.one()

        if claim do
          installation =
            Repo.one(
              from i in Installation,
                where: i.provider == "github",
                where: i.provider_id == ^to_string(installation["id"])
            )

          bounties =
            Repo.all(
              from(b in Bounty,
                join: t in assoc(b, :ticket),
                join: o in assoc(b, :owner),
                left_join: u in assoc(b, :creator),
                left_join: c in assoc(o, :customer),
                left_join: p in assoc(c, :default_payment_method),
                where: t.id == ^claim.target_id,
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
                         owner: repository["owner"]["login"],
                         repo: repository["name"],
                         number: pull_request["number"]
                       },
                       bounty_id: autopayable_bounty.id,
                       claims: [claim]
                     ),
                   {:ok, _invoice} <-
                     Algora.Stripe.pay_invoice(invoice, %{
                       payment_method: autopayable_bounty.owner.customer.default_payment_method.provider_id,
                       off_session: true
                     }) do
                Logger.info("Autopay successful (#{autopayable_bounty.owner.name} - #{autopayable_bounty.amount}).")
              else
                {:error, reason} = error ->
                  Logger.error(
                    "Autopay failed (#{autopayable_bounty.owner.name} - #{autopayable_bounty.amount}): #{inspect(reason)}"
                  )

                  error
              end
            end

          unpaid_bounties =
            Enum.filter(
              bounties,
              &case autopay_result do
                {:ok, _} -> &1.id != autopayable_bounty.id
                _ -> true
              end
            )

          sponsors_to_notify =
            unpaid_bounties
            |> Enum.map(&(&1.creator || &1.owner))
            |> Enum.map_join(", ", &"@#{&1.provider_login}")

          if unpaid_bounties != [] do
            Github.create_issue_comment(
              token,
              claim.target.repository.user.provider_login,
              claim.target.repository.name,
              claim.target.number,
              "💡 @#{claim.user.provider_login}'s PR has been merged. You can visit [Algora](#{Claim.reward_url(claim)}) to award the bounty." <>
                if(sponsors_to_notify == "", do: "", else: "\n\ncc #{sponsors_to_notify}")
            )
          end

          :ok
        end
      else
        {:error, reason} = error ->
          Logger.error("Error processing event: #{inspect(reason)}")
          error
      end
    end
  end

  defp process_event(_event_action, _params) do
    :ok
  end

  defp execute_command(event_action, {:bounty, args}, author, params)
       when event_action in ["issues.opened", "issues.edited", "issue_comment.created", "issue_comment.edited"] do
    [event, _action] = String.split(event_action, ".")

    amount = args[:amount]
    repo = params["repository"]
    issue = params["issue"]
    installation_id = params["installation"]["id"]

    {command_source, command_id} =
      case event do
        "issue_comment" -> {:comment, params["comment"]["id"]}
        _ -> {:ticket, issue["id"]}
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
    with {:ok, "admin"} <- get_permissions(author, params),
         {:ok, token} <- Github.get_installation_token(installation_id),
         {:ok, installation} <-
           Workspace.fetch_installation_by(provider: "github", provider_id: to_string(installation_id)),
         {:ok, owner} <- Accounts.fetch_user_by(id: installation.connected_user_id),
         {:ok, creator} <- Workspace.ensure_user(token, repo["owner"]["login"]) do
      Bounties.create_bounty(
        %{
          creator: creator,
          owner: owner,
          amount: amount,
          ticket_ref: %{owner: repo["owner"]["login"], repo: repo["name"], number: issue["number"]}
        },
        strategy: strategy,
        installation_id: installation_id,
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

  defp execute_command(event_action, {:tip, args}, author, params)
       when event_action in ["issue_comment.created", "issue_comment.edited"] do
    amount = args[:amount]
    recipient = args[:recipient]
    repo = params["repository"]
    issue = params["issue"]
    installation_id = params["installation"]["id"]

    # TODO: handle missing amount
    # TODO: handle missing recipient
    # TODO: handle tip to self
    # TODO: handle autopay with cooldown
    # TODO: community tips?
    case get_permissions(author, params) do
      {:ok, "admin"} ->
        Bounties.create_tip_intent(
          %{
            recipient: recipient,
            amount: amount,
            ticket_ref: %{owner: repo["owner"]["login"], repo: repo["name"], number: issue["number"]}
          },
          installation_id: installation_id
        )

      {:ok, _permission} ->
        {:error, :unauthorized}

      {:error, _reason} = error ->
        error
    end
  end

  defp execute_command(event_action, {:attempt, args}, author, params)
       when event_action in ["issue_comment.created", "issue_comment.edited"] do
    installation_id = params["installation"]["id"]
    repo = params["repository"]
    issue = params["issue"]

    source_ticket_ref = %{
      owner: repo["owner"]["login"],
      repo: repo["name"],
      number: issue["number"]
    }

    target_ticket_ref =
      %{
        owner: args[:ticket_ref][:owner] || source_ticket_ref.owner,
        repo: args[:ticket_ref][:repo] || source_ticket_ref.repo,
        number: args[:ticket_ref][:number]
      }

    with true <- source_ticket_ref == target_ticket_ref,
         {:ok, token} <- Github.get_installation_token(installation_id),
         {:ok, ticket} <- Workspace.ensure_ticket(token, repo["owner"]["login"], repo["name"], issue["number"]),
         {:ok, user} <- Workspace.ensure_user(token, author["login"]),
         {:ok, attempt} <- Bounties.get_or_create_attempt(%{ticket: ticket, user: user}),
         {:ok, _} <- Bounties.refresh_bounty_response(token, target_ticket_ref, ticket) do
      {:ok, attempt}
    end
  end

  defp execute_command(event_action, {:claim, args}, author, params)
       when event_action in ["pull_request.opened", "pull_request.reopened", "pull_request.edited"] do
    installation_id = params["installation"]["id"]
    pull_request = params["pull_request"]
    repo = params["repository"]

    source_ticket_ref = %{
      owner: repo["owner"]["login"],
      repo: repo["name"],
      number: pull_request["number"]
    }

    target_ticket_ref =
      %{
        owner: args[:ticket_ref][:owner] || source_ticket_ref.owner,
        repo: args[:ticket_ref][:repo] || source_ticket_ref.repo,
        number: args[:ticket_ref][:number]
      }

    with {:ok, token} <- Github.get_installation_token(installation_id),
         {:ok, user} <- Workspace.ensure_user(token, author["login"]) do
      Bounties.claim_bounty(
        %{
          user: user,
          coauthor_provider_logins: (args[:splits] || []) |> Enum.map(& &1[:recipient]) |> Enum.uniq(),
          target_ticket_ref: target_ticket_ref,
          source_ticket_ref: source_ticket_ref,
          status: if(pull_request["merged_at"], do: :approved, else: :pending),
          type: :pull_request
        },
        installation_id: installation_id
      )
    end
  end

  defp execute_command(_event_action, _command, _author, _params) do
    {:ok, nil}
  end

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
         |> Enum.reject(&is_nil/1)}

      {:error, reason} = error ->
        Logger.error("Error parsing commands: #{inspect(reason)}")
        error
    end
  end

  def process_commands(%Webhook{hook_id: hook_id}, event_action, author, body, params) do
    case build_commands(body) do
      {:ok, commands} ->
        Enum.reduce_while(commands, {:ok, []}, fn command, {:ok, results} ->
          case execute_command(event_action, command, author, params) do
            {:ok, result} ->
              {:cont, {:ok, [result | results]}}

            error ->
              Logger.error(
                "Command execution failed for #{event_action}(#{hook_id}): #{inspect(command)}: #{inspect(error)}"
              )

              {:halt, error}
          end
        end)

      {:error, reason} = error ->
        Logger.error("Error parsing commands: #{inspect(reason)}")
        error
    end
  end

  defp get_author("issues", params), do: params["issue"]["user"]
  defp get_author("issue_comment", params), do: params["comment"]["user"]
  defp get_author("pull_request", params), do: params["pull_request"]["user"]
  defp get_author("pull_request_review", params), do: params["review"]["user"]
  defp get_author("pull_request_review_comment", params), do: params["comment"]["user"]
  defp get_author(_event, _params), do: nil

  defp get_body("issues", params), do: params["issue"]["body"]
  defp get_body("issue_comment", params), do: params["comment"]["body"]
  defp get_body("pull_request", params), do: params["pull_request"]["body"]
  defp get_body("pull_request_review", params), do: params["review"]["body"]
  defp get_body("pull_request_review_comment", params), do: params["comment"]["body"]
  defp get_body(_event, _params), do: nil
end
