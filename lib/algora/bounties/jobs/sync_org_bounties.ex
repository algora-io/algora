defmodule Algora.Bounties.Jobs.SyncOrgBounties do
  @moduledoc false
  use Oban.Worker,
    queue: :background,
    max_attempts: 2,
    unique: [fields: [:args], period: 3600]

  alias Algora.Bounties
  alias Algora.Github
  alias Algora.Github.Command
  alias Algora.Workspace

  def perform(%Oban.Job{args: %{"owner_id" => owner_id}}) do
    token = Github.TokenPool.maybe_get_token() || Github.pat() || "algora-sync"

    owner_id
    |> list_open_bounties()
    |> Enum.each(&sync_bounty(&1, token))

    :ok
  end

  defp list_open_bounties(owner_id) do
    Bounties.list_bounties(
      owner_id: owner_id,
      status: :open,
      limit: :infinity
    )
    |> Enum.uniq_by(fn bounty ->
      {
        bounty.repository.owner.provider_login,
        bounty.repository.name,
        bounty.ticket.number
      }
    end)
  end

  defp sync_bounty(bounty, token) do
    target_ref = target_ref(bounty)

    with {:ok, target_ticket} <-
           Workspace.ensure_ticket(
             token,
             target_ref.owner,
             target_ref.repo,
             target_ref.number
           ),
         {:ok, _ticket} <-
           Workspace.update_ticket_from_github(
             token,
             target_ref.owner,
             target_ref.repo,
             target_ref.number
           ) do
      sync_attempts(token, target_ticket, target_ref)
      sync_claims(token, target_ref)
    end
  end

  defp sync_attempts(token, target_ticket, target_ref) do
    with {:ok, comments} <- Github.list_issue_comments(token, target_ref.owner, target_ref.repo, target_ref.number) do
      Enum.each(comments, fn comment ->
        Enum.each(parse_commands(comment["body"]), fn
          {:attempt, args} ->
            if same_ticket?(command_target_ref(target_ref, args), target_ref) do
              with {:ok, user} <- Workspace.ensure_user(token, comment["user"]["login"]) do
                Bounties.get_or_create_attempt(%{ticket: target_ticket, user: user})
              end
            end

          _ ->
            :ok
        end)
      end)
    end
  end

  defp sync_claims(token, target_ref) do
    target_ref
    |> claim_queries()
    |> Enum.flat_map(fn query ->
      case Github.search_issues(token, query, per_page: 20) do
        {:ok, %{"items" => items}} -> items
        _ -> []
      end
    end)
    |> Enum.uniq_by(& &1["number"])
    |> Enum.each(&sync_pull_request_claim(token, target_ref, &1["number"]))
  end

  defp sync_pull_request_claim(token, target_ref, pr_number) do
    with {:ok, pull_request} <- Github.get_pull_request(token, target_ref.owner, target_ref.repo, pr_number),
         true <- pull_request["state"] == "open" do
      sync_claim_from_body(token, target_ref, pull_request)

      with {:ok, comments} <- Github.list_issue_comments(token, target_ref.owner, target_ref.repo, pr_number) do
        Enum.each(comments, &sync_claim_from_comment(token, target_ref, pr_number, &1))
      end
    else
      _ -> :ok
    end
  end

  defp sync_claim_from_body(token, target_ref, pull_request) do
    commands = parse_commands(pull_request["body"] || "")

    Enum.each(commands, fn
      {:claim, args} ->
        maybe_create_claim(
          token,
          target_ref,
          command_target_ref(target_ref, args),
          pull_request["number"],
          pull_request["user"]["login"],
          claim_status(pull_request),
          args[:splits] || []
        )

      _ ->
        :ok
    end)
  end

  defp sync_claim_from_comment(token, target_ref, pr_number, comment) do
    Enum.each(parse_commands(comment["body"]), fn
      {:claim, args} ->
        maybe_create_claim(
          token,
          target_ref,
          command_target_ref(target_ref, args),
          pr_number,
          comment["user"]["login"],
          :pending,
          args[:splits] || []
        )

      _ ->
        :ok
    end)
  end

  defp maybe_create_claim(token, target_ref, parsed_target_ref, pr_number, claimant_login, status, splits) do
    if same_ticket?(parsed_target_ref, target_ref) do
      with {:ok, user} <- Workspace.ensure_user(token, claimant_login) do
        coauthors =
          splits
          |> Enum.map(& &1[:recipient])
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()

        Bounties.claim_bounty(%{
          user: user,
          coauthor_provider_logins: coauthors,
          target_ticket_ref: target_ref,
          source_ticket_ref: %{owner: target_ref.owner, repo: target_ref.repo, number: pr_number},
          status: status,
          type: :pull_request
        })
      end
    end
  end

  defp claim_queries(%{owner: owner, repo: repo, number: number}) do
    [
      ~s(repo:#{owner}/#{repo} is:pr "/claim ##{number}"),
      ~s(repo:#{owner}/#{repo} is:pr "/claim #{repo}##{number}"),
      ~s(repo:#{owner}/#{repo} is:pr "/claim #{owner}/#{repo}##{number}"),
      ~s(repo:#{owner}/#{repo} is:pr "issues/#{number}")
    ]
  end

  defp parse_commands(body) do
    case Command.parse(body) do
      {:ok, commands} ->
        commands
        |> Enum.map(&build_command(&1, commands))
        |> Enum.reject(&is_nil/1)
        |> Enum.reduce([], fn
          {:claim, _} = claim, acc ->
            if Enum.any?(acc, &match?({:claim, _}, &1)), do: acc, else: [claim | acc]

          command, acc ->
            [command | acc]
        end)
        |> Enum.reverse()

      _ ->
        []
    end
  end

  defp build_command({:claim, args}, commands) do
    splits = Keyword.get_values(commands, :split)
    {:claim, Keyword.put(args, :splits, splits)}
  end

  defp build_command({:split, _args}, _commands), do: nil
  defp build_command(command, _commands), do: command

  defp claim_status(%{"merged_at" => merged_at}) when not is_nil(merged_at), do: :approved
  defp claim_status(_pull_request), do: :pending

  defp command_target_ref(default_ref, args) do
    %{
      owner: args[:ticket_ref][:owner] || default_ref.owner,
      repo: args[:ticket_ref][:repo] || default_ref.repo,
      number: args[:ticket_ref][:number]
    }
  end

  defp same_ticket?(left, right) do
    left.owner == right.owner and left.repo == right.repo and left.number == right.number
  end

  defp target_ref(bounty) do
    %{
      owner: bounty.repository.owner.provider_login,
      repo: bounty.repository.name,
      number: bounty.ticket.number
    }
  end
end
