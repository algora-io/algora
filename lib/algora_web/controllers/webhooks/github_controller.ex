defmodule AlgoraWeb.Webhooks.GithubController do
  use AlgoraWeb, :controller

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Github
  alias Algora.Github.Webhook
  alias Algora.Workspace

  require Logger

  # TODO: persist & alert about failed deliveries
  # TODO: auto-retry failed deliveries with exponential backoff

  def new(conn, params) do
    with {:ok, webhook} <- Webhook.new(conn),
         {:ok, _} <- process_commands(webhook, params) do
      conn |> put_status(:accepted) |> json(%{status: "ok"})
    else
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

  defp execute_command(event_action, {:bounty, args}, author, params)
       when event_action in ["issues.opened", "issues.edited", "issue_comment.created", "issue_comment.edited"] do
    [event, _action] = String.split(event_action, ".")
    amount = args[:amount]
    repo = params["repository"]
    issue = params["issue"]
    installation_id = params["installation"]["id"]

    {command_source, command_id} =
      case event do
        "issue_comment" ->
          {:comment, params["comment"]["id"]}

        _ ->
          {:ticket, issue["id"]}
      end

    dbg({command_source, command_id})

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

  def process_commands(%Webhook{event: event, hook_id: hook_id}, params) do
    author = get_author(event, params)
    body = get_body(event, params)

    event_action = event <> "." <> params["action"]

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
  defp get_author(_event, _params), do: nil

  defp get_body("issues", params), do: params["issue"]["body"]
  defp get_body("issue_comment", params), do: params["comment"]["body"]
  defp get_body("pull_request", params), do: params["pull_request"]["body"]
  defp get_body(_event, _params), do: nil
end
