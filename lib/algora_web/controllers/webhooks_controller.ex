defmodule AlgoraWeb.WebhooksController do
  use AlgoraWeb, :controller
  require Logger
  alias Algora.Github.Webhook

  # TODO: persist & alert about failed deliveries
  # TODO: auto-retry failed deliveries with exponential backoff

  def new(conn, params) do
    try do
      with {:ok, %Webhook{delivery: _delivery, event: event, installation_id: _installation_id}} <-
             Webhook.new(conn) do
        event_action =
          case params["action"] do
            nil -> event
            action -> "#{event}.#{action}"
          end

        handle_event(event_action, params)

        conn
        |> put_status(:accepted)
        |> json(%{status: "ok"})
      else
        {:error, %Jason.EncodeError{}} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: "Invalid payload"})

        {:error, :missing_header} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: "Missing header"})

        {:error, :signature_mismatch} ->
          conn
          |> put_status(:unauthorized)
          |> json(%{error: "Signature mismatch"})

        {:error, reason} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: reason})
      end
    rescue
      e ->
        Logger.error("Unexpected error: #{inspect(e)}")

        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Internal server error"})
    end
  end

  defp handle_event("issues.opened", params) do
    process_commands(params["issue"]["body"])
    Logger.info("An issue was opened with this title: #{params["issue"]["title"]}")
  end

  defp handle_event("issues.edited", params) do
    process_commands(params["issue"]["body"])
    Logger.info("An issue was edited")
  end

  defp handle_event("issues.closed", params) do
    Logger.info("An issue was closed by #{params["issue"]["user"]["login"]}")
  end

  defp handle_event("issue_comment.created", params) do
    process_commands(params["comment"]["body"])
    Logger.info("Comment created by #{params["comment"]["user"]["login"]}")
  end

  defp handle_event("issue_comment.edited", params) do
    process_commands(params["comment"]["body"])
    Logger.info("Comment edited by #{params["comment"]["user"]["login"]}")
  end

  defp handle_event("pull_request.opened", params) do
    process_commands(params["pull_request"]["body"])
    Logger.info("Pull request opened by #{params["pull_request"]["user"]["login"]}")
  end

  defp handle_event("pull_request.edited", params) do
    process_commands(params["pull_request"]["body"])
    Logger.info("Pull request edited by #{params["pull_request"]["user"]["login"]}")
  end

  defp handle_event("ping", _params) do
    Logger.info("GitHub sent the ping event")
  end

  defp handle_event(event_action, _params) do
    Logger.info("Unhandled event action: #{event_action}")
  end

  defp process_commands(body) when is_binary(body) do
    commands = extract_commands(body)
    Enum.each(commands, &execute_command/1)
  end

  defp process_commands(_), do: nil

  defp extract_commands(body) do
    ~r{^/(\w+)(?:\s+(.+))?}m
    |> Regex.scan(body, capture: :all_but_first)
    |> Enum.map(fn
      [command] -> {command, nil}
      [command, args] -> {command, String.trim(args)}
    end)
  end

  defp execute_command({"bounty", args}) do
    case args do
      nil ->
        Logger.info("Bounty command without amount")

      args ->
        case Regex.run(~r/\$(\d+)/, args) do
          [_, amount] -> Logger.info("Bounty command with amount: $#{amount}")
          nil -> Logger.info("Invalid bounty amount format")
        end
    end
  end

  defp execute_command({"tip", args}) when not is_nil(args) do
    amount = Regex.run(~r/\$(\d+)/, args)
    user = Regex.run(~r/@(\w+)/, args)

    case {amount, user} do
      {[_, amount], [_, user]} -> Logger.info("Tip $#{amount} to @#{user}")
      {[_, amount], nil} -> Logger.info("Tip $#{amount} to unspecified user")
      {nil, [_, user]} -> Logger.info("Tip (no amount) to @#{user}")
      _ -> Logger.info("Invalid tip format")
    end
  end

  defp execute_command({"approve", _}), do: Logger.info("Approve command")

  defp execute_command({"split", args}) when not is_nil(args) do
    case Regex.run(~r/@(\w+)\s+%(\d+)/, args) do
      [_, user, percentage] -> Logger.info("Split #{percentage}% with @#{user}")
      nil -> Logger.info("Invalid split format")
    end
  end

  defp execute_command({"claim", args}) when not is_nil(args) do
    cond do
      String.starts_with?(args, "http") ->
        case Regex.run(~r{github\.com/([^/]+)/([^/]+)/(?:issues|pulls)/(\d+)}, args) do
          [_, owner, repo, number] -> Logger.info("Claim #{owner}/#{repo}##{number}")
          nil -> Logger.info("Invalid claim URL format")
        end

      String.match?(args, ~r{^[^/]+/[^/]+#\d+$}) ->
        [owner_repo, number] = String.split(args, "#")
        Logger.info("Claim #{owner_repo}##{number}")

      String.match?(args, ~r{^#\d+$}) ->
        number = String.replace(args, "#", "")
        Logger.info("Claim issue/PR ##{number}")

      true ->
        Logger.info("Invalid claim format")
    end
  end

  defp execute_command({command, _}), do: Logger.info("Unhandled command: #{command}")
end
