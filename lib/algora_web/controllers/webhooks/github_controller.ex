defmodule AlgoraWeb.Webhooks.GithubController do
  use AlgoraWeb, :controller

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Tip
  alias Algora.Github
  alias Algora.Github.Webhook
  alias Algora.Organizations.Member
  alias Algora.Payments.Customer
  alias Algora.PSP.Invoice
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace
  alias Algora.Workspace.CommandResponse
  alias Algora.Workspace.Installation

  require Logger

  def process_delivery(webhook) do
    with :ok <- ensure_human_author(webhook),
         {:ok, commands} <- process_commands(webhook),
         :ok <- process_event(webhook, commands) do
      Logger.debug("✅ #{inspect(webhook.event_action)}")
      :ok
    else
      {:error, :bot_event} ->
        :ok

      {:error, reason} ->
        Logger.error("❌ #{inspect(webhook.event_action)}: #{inspect(reason)}")
        alert(webhook, {:error, reason})
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("❌ #{inspect(webhook.event_action)}: #{inspect(error)}")
      alert(webhook, {:error, error})
      {:error, error}
  end

  defp ensure_human_author(%Webhook{author: author}) do
    case author do
      %{"type" => "Bot"} -> {:error, :bot_event}
      _ -> :ok
    end
  end

  defp authorize_user(%Webhook{} = webhook) do
    case check_org_permissions(webhook) do
      {:ok, role} -> {:ok, role}
      {:error, :unauthorized} -> check_repo_permissions(webhook)
    end
  end

  defp check_repo_permissions(%Webhook{payload: payload, author: author}) do
    repo = payload["repository"]

    with {:ok, token} <- Github.get_installation_token(payload["installation"]["id"]),
         {:ok, %{"permission" => permission}} <-
           Github.get_repository_permissions(
             token,
             repo["owner"]["login"],
             repo["name"],
             author["login"]
           ) do
      case permission do
        "admin" -> {:ok, :admin}
        "write" -> {:ok, :mod}
        _ -> {:error, :unauthorized}
      end
    end
  end

  defp check_org_permissions(%Webhook{payload: payload, author: author}) do
    installation_id = payload["installation"]["id"]

    with {:ok, token} <- Github.get_installation_token(installation_id),
         {:ok, installation} <-
           Repo.fetch_by(Installation,
             provider: "github",
             provider_id: to_string(installation_id)
           ),
         {:ok, user} <- Workspace.ensure_user(token, author["login"]) do
      member =
        Repo.one(
          from m in Member,
            join: o in assoc(m, :org),
            where: o.id == ^installation.connected_user_id and m.user_id == ^user.id
        )

      case member do
        %Member{role: :admin} -> {:ok, :admin}
        %Member{role: :mod} -> {:ok, :mod}
        _ -> {:error, :unauthorized}
      end
    end
  end

  defp process_event(%Webhook{event_action: "issues.closed"} = webhook, _commands),
    do: handle_ticket_state_change(webhook)

  defp process_event(%Webhook{event_action: "issues.deleted"} = webhook, _commands),
    do: handle_ticket_state_change(webhook)

  defp process_event(%Webhook{event_action: "issues.reopened"} = webhook, _commands),
    do: handle_ticket_state_change(webhook)

  defp process_event(%Webhook{event_action: "pull_request.reopened"} = webhook, _commands),
    do: handle_ticket_state_change(webhook)

  defp process_event(
         %Webhook{event_action: "pull_request.closed", payload: %{"pull_request" => %{"merged_at" => nil}}} = webhook,
         _commands
       ),
       do: handle_ticket_state_change(webhook)

  defp process_event(%Webhook{event_action: "pull_request.closed", payload: payload} = webhook, _commands) do
    _res = handle_ticket_state_change(webhook)

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
                 where: c.status != :cancelled,
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
              from(c in Claim, where: c.group_id == ^group_id, where: c.status != :cancelled),
              set: [status: :approved]
            )

            Repo.all(
              from c in Claim,
                join: t in assoc(c, :target),
                join: tr in assoc(t, :repository),
                join: tru in assoc(tr, :user),
                join: u in assoc(c, :user),
                where: c.group_id == ^group_id,
                where: c.status != :cancelled,
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
          Repo.get_by(Installation,
            provider: "github",
            provider_id: to_string(payload["installation"]["id"])
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
            &(not &1.autopay_disabled and
                not is_nil(installation) and
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
                       amount: autopayable_bounty.amount,
                       idempotency_key: "bounty-#{autopayable_bounty.id}"
                     },
                     ticket_ref: %{
                       owner: payload["repository"]["owner"]["login"],
                       repo: payload["repository"]["name"],
                       number: payload["pull_request"]["number"]
                     },
                     bounty: autopayable_bounty,
                     claims: claims
                   ),
                 {:ok, _invoice} <-
                   Invoice.pay(
                     invoice,
                     %{
                       payment_method: autopayable_bounty.owner.customer.default_payment_method.provider_id,
                       off_session: true
                     }
                   ) do
              Algora.Activities.alert(
                "Autopay successful (#{autopayable_bounty.owner.name} - #{autopayable_bounty.amount}).",
                :debug
              )

              :ok
            else
              {:error, reason} ->
                Algora.Activities.alert(
                  "Autopay failed (#{autopayable_bounty.owner.name} - #{autopayable_bounty.amount}): #{inspect(reason)}",
                  :error
                )

                :error
            end
          end

        if autopay_result do
          autopay_result
        else
          sponsors_to_notify =
            bounties
            |> Enum.map(&(&1.creator || &1.owner))
            |> Enum.map_join(", ", &"@#{&1.provider_login}")

          if bounties != [] do
            names =
              claims
              |> Enum.map(fn c -> "@#{c.user.provider_login}" end)
              |> Algora.Util.format_name_list()

            Github.create_issue_comment(
              token,
              primary_claim.target.repository.user.provider_login,
              primary_claim.target.repository.name,
              primary_claim.target.number,
              "🎉 The pull request of #{names} has been merged. The bounty can be rewarded [here](#{Claim.reward_url(primary_claim)})" <>
                if(sponsors_to_notify == "", do: "", else: "\n\ncc #{sponsors_to_notify}")
            )
          end
        end

        :ok
      end
    end
  end

  defp process_event(%Webhook{event_action: event_action, payload: payload}, commands)
       when event_action in ["pull_request.opened", "pull_request.reopened", "pull_request.edited"] do
    source =
      Workspace.get_ticket(
        payload["repository"]["owner"]["login"],
        payload["repository"]["name"],
        payload["pull_request"]["number"]
      )

    if source do
      source
      |> change(%{description: payload["pull_request"]["body"]})
      |> Repo.update()
    end

    has_claim = Enum.any?(commands, &match?({:claim, _}, &1))

    if source && !has_claim do
      source.id
      |> Bounties.get_active_claims()
      |> Bounties.cancel_all_claims()
    else
      :ok
    end
  end

  defp process_event(_webhook, _commands), do: :ok

  defp execute_command(%Webhook{event_action: event_action, payload: payload, author: author} = webhook, {:bounty, args})
       when event_action in [
              "issues.opened",
              "issues.edited",
              "issue_comment.created",
              "issue_comment.edited",
              "pull_request.opened",
              "pull_request.edited"
            ] do
    amount = args[:amount]

    {command_source, command_id} =
      case webhook.event do
        "issue_comment" -> {:comment, payload["comment"]["id"]}
        "issues" -> {:ticket, payload["issue"]["id"]}
        "pull_request" -> {:ticket, payload["pull_request"]["id"]}
      end

    ticket_number = get_github_ticket(webhook)["number"]

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
    with {:ok, role} <- authorize_user(webhook),
         true <- Member.can_create_bounty?(role),
         {:ok, token} <- Github.get_installation_token(payload["installation"]["id"]),
         {:ok, installation} <-
           Workspace.fetch_installation_by(
             provider: "github",
             provider_id: to_string(payload["installation"]["id"])
           ),
         {:ok, owner} <- Accounts.fetch_user_by(id: installation.connected_user_id),
         {:ok, creator} <- Workspace.ensure_user(token, author["login"]) do
      Bounties.create_bounty(
        %{
          creator: creator,
          owner: owner,
          amount: amount,
          ticket_ref: %{
            owner: payload["repository"]["owner"]["login"],
            repo: payload["repository"]["name"],
            number: ticket_number
          }
        },
        strategy: strategy,
        installation_id: payload["installation"]["id"],
        command_id: command_id,
        command_source: command_source
      )
    else
      false ->
        {:error, :unauthorized}

      {:error, _reason} = error ->
        error
    end
  end

  defp execute_command(%Webhook{event_action: event_action, payload: payload} = webhook, {:tip, args})
       when event_action in [
              "issue_comment.created",
              "issue_comment.edited",
              "pull_request_review.submitted",
              "pull_request_review_comment.created"
            ] do
    amount = args[:amount]

    ticket_ref = %{
      owner: payload["repository"]["owner"]["login"],
      repo: payload["repository"]["name"],
      number: get_github_ticket(webhook)["number"]
    }

    with {:ok, role} <- authorize_user(webhook),
         true <- Member.can_create_bounty?(role) do
      installation =
        Repo.get_by(Installation,
          provider: "github",
          provider_id: to_string(payload["installation"]["id"])
        )

      customer =
        Repo.one(
          from c in Customer,
            left_join: p in assoc(c, :default_payment_method),
            where: c.user_id == ^installation.connected_user_id,
            select_merge: %{default_payment_method: p}
        )

      {:ok, recipient} = get_tip_recipient(webhook, {:tip, args})

      {:ok, token} = Github.get_installation_token(payload["installation"]["id"])

      {:ok, ticket} =
        Workspace.ensure_ticket(token, ticket_ref.owner, ticket_ref.repo, ticket_ref.number)

      autopay_cooldown_expired? = fn ->
        from(t in Tip,
          join: recipient in assoc(t, :recipient),
          where: recipient.provider_login == ^recipient,
          where: t.ticket_id == ^ticket.id,
          where: t.status != :cancelled,
          order_by: [desc: t.inserted_at],
          limit: 1
        )
        |> Repo.one()
        |> case do
          nil ->
            true

          tip ->
            DateTime.diff(DateTime.utc_now(), tip.inserted_at, :millisecond) > :timer.hours(1)
        end
      end

      autopayable? =
        not is_nil(installation) and
          not is_nil(customer) and
          not is_nil(customer.default_payment_method) and
          not is_nil(recipient) and
          not is_nil(amount) and
          autopay_cooldown_expired?.()

      autopay_result =
        if autopayable? do
          with {:ok, owner} <- Accounts.fetch_user_by(id: installation.connected_user_id),
               {:ok, creator} <-
                 Workspace.ensure_user(token, payload["repository"]["owner"]["login"]),
               {:ok, recipient} <- Workspace.ensure_user(token, recipient),
               {:ok, tip} <-
                 Bounties.do_create_tip(
                   %{creator: creator, owner: owner, recipient: recipient, amount: amount},
                   ticket_ref: ticket_ref,
                   installation_id: payload["installation"]["id"]
                 ),
               {:ok, invoice} <-
                 Bounties.create_invoice(
                   %{
                     owner: owner,
                     amount: amount,
                     idempotency_key: "tip-#{recipient.provider_login}-#{webhook.delivery}"
                   },
                   ticket_ref: ticket_ref,
                   tip_id: tip.id,
                   recipient: recipient
                 ),
               {:ok, _invoice} <-
                 Invoice.pay(invoice, %{payment_method: customer.default_payment_method.provider_id, off_session: true}) do
            Algora.Activities.alert(
              "Autopay successful (#{payload["repository"]["full_name"]}##{ticket_ref.number} - #{amount}).",
              :debug
            )

            {:ok, tip}
          else
            {:error, reason} ->
              Algora.Activities.alert(
                "Autopay failed (#{payload["repository"]["full_name"]}##{ticket_ref.number} - #{amount}): #{inspect(reason)}",
                :error
              )

              {:error, reason}
          end
        end

      case autopay_result do
        {:ok, tip} ->
          {:ok, tip}

        _ ->
          Bounties.create_tip_intent(
            %{
              recipient: recipient,
              amount: amount,
              ticket_ref: ticket_ref
            },
            installation_id: payload["installation"]["id"]
          )
      end
    else
      false ->
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
             source_ticket_ref.owner,
             source_ticket_ref.repo,
             source_ticket_ref.number
           ),
         {:ok, user} <- Workspace.ensure_user(token, author["login"]),
         {:ok, attempt} <- Bounties.get_or_create_attempt(%{ticket: ticket, user: user}) do
      Bounties.try_refresh_bounty_response(token, target_ticket_ref, ticket)
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
         {:ok, user} <- Workspace.ensure_user(token, author["login"]),
         {:ok, target_ticket} <-
           Workspace.ensure_ticket(
             token,
             target_ticket_ref.owner,
             target_ticket_ref.repo,
             target_ticket_ref.number
           ),
         {:ok, claims} <-
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
           ) do
      Bounties.try_refresh_bounty_response(token, target_ticket_ref, target_ticket)
      {:ok, claims}
    end
  end

  defp execute_command(_webhook, {cmd, _args}) when cmd in [:bounty, :tip, :claim, :attempt] do
    {:ok, nil}
  end

  defp execute_command(webhook, command) do
    github_ticket = get_github_ticket(webhook)

    Algora.Activities.alert(
      "Received unknown command: #{inspect(command)}. Ticket: #{github_ticket["html_url"]}. Hook ID: #{webhook.hook_id}",
      :error
    )

    {:error, :unknown_command}
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
         |> Enum.reject(&is_nil/1)
         # keep only the first claim command if multiple claims are present
         |> Enum.reduce([], fn
           {:claim, _} = claim, acc ->
             if Enum.any?(acc, &match?({:claim, _}, &1)), do: acc, else: [claim | acc]

           command, acc ->
             [command | acc]
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

  defp get_tip_recipient(%Webhook{payload: payload, author: author} = webhook, {:tip, args}) do
    ticket = get_github_ticket(webhook)

    res =
      case args[:recipient] do
        nil ->
          with {:ok, token} <- Github.get_installation_token(payload["installation"]["id"]),
               {:ok, user} <- Workspace.ensure_user(token, ticket["user"]["login"]) do
            {:ok, user.provider_login}
          end

        recipient ->
          {:ok, recipient}
      end

    case res do
      {:ok, recipient} ->
        {:ok, ensure_valid_recipient(recipient, author)}

      error ->
        error
    end
  end

  defp ensure_valid_recipient(recipient, author) do
    if recipient == author["login"], do: nil, else: recipient
  end

  defp handle_ticket_state_change(%Webhook{payload: payload, event_action: event_action} = webhook) do
    github_ticket = get_github_ticket(webhook)

    state =
      if event_action == "issues.deleted" do
        :closed
      else
        String.to_existing_atom(github_ticket["state"])
      end

    case Workspace.get_ticket(
           payload["repository"]["owner"]["login"],
           payload["repository"]["name"],
           github_ticket["number"]
         ) do
      nil ->
        :ok

      ticket ->
        case ticket
             |> change(
               state: state,
               closed_at: Util.to_date!(github_ticket["closed_at"]),
               merged_at: Util.to_date!(github_ticket["merged_at"])
             )
             |> Repo.update() do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp alert(%Webhook{event_action: event_action} = webhook, {:error, error}) do
    message =
      case get_github_ticket(webhook) do
        github_ticket when not is_nil(github_ticket) ->
          "Error processing event: #{event_action}. Ticket: #{github_ticket["html_url"]}. Hook ID: #{webhook.hook_id}. Error: #{inspect(error)}"

        _ ->
          "Error processing event: #{event_action}. Hook ID: #{webhook.hook_id}. Error: #{inspect(error)}"
      end

    Algora.Activities.alert(message, :error)
  end

  defp get_github_ticket(%Webhook{event: event, payload: payload}) do
    case event do
      "issues" -> payload["issue"]
      "issue_comment" -> payload["issue"]
      "pull_request" -> payload["pull_request"]
      "pull_request_review" -> payload["pull_request"]
      "pull_request_review_comment" -> payload["pull_request"]
      _ -> nil
    end
  end
end
