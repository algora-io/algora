defmodule AlgoraWeb.WebhooksController do
  use AlgoraWeb, :controller
  require Logger
  alias Algora.Github.Webhook
  alias Algora.Github

  # TODO: persist & alert about failed deliveries
  # TODO: auto-retry failed deliveries with exponential backoff

  def new(conn, params) do
    try do
      with {:ok, %Webhook{delivery: _delivery, event: event, installation_id: _installation_id}} <-
             Webhook.new(conn) do
        author = get_author(event, params)
        body = get_body(event, params)
        process_commands(body, author, params)

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

  # TODO: cache installation tokens
  defp get_permissions(author, %{"repository" => repository, "installation" => installation}) do
    with {:ok, %{"token" => access_token}} <- Github.get_installation_token(installation["id"]),
         {:ok, %{"permission" => permission}} <-
           Github.get_repository_permissions(
             access_token,
             repository["owner"]["login"],
             repository["name"],
             author["login"]
           ) do
      {:ok, permission}
    else
      error -> error
    end
  end

  defp get_permissions(_author, _params), do: {:error, :invalid_params}

  defp execute_command({"bounty", args}, author, params) do
    with {:ok, "admin"} <- get_permissions(author, params) do
      case extract_amount(args) do
        nil -> {:ok, :open_to_bids}
        amount -> {:ok, amount}
      end
    else
      {:ok, _permission} -> {:error, :unauthorized}
      {:error, error} -> {:error, error}
    end
  end

  # Helper function to extract amount from various formats
  defp extract_amount(nil), do: nil

  defp extract_amount(args) do
    # Remove commas before parsing and handle optional $ and decimal places
    case Regex.run(~r/(\d+(?:,\d{3})*(?:\.\d+)?)\$?/, args) do
      [_, amount] ->
        {amount, _} = amount |> String.replace(",", "") |> Float.parse()
        trunc(amount)

      nil ->
        nil
    end
  end

  defp execute_command({"tip", args}, _author, _params) when not is_nil(args) do
    amount = Regex.run(~r/\$(\d+)/, args)
    receiver = Regex.run(~r/@(\w+)/, args)

    case {amount, receiver} do
      {[_, amount], [_, receiver]} -> Logger.info("Tip $#{amount} to @#{receiver}")
      {[_, amount], nil} -> Logger.info("Tip $#{amount} to unspecified receiver")
      {nil, [_, receiver]} -> Logger.info("Tip (no amount) to @#{receiver}")
      _ -> Logger.info("Invalid tip format")
    end
  end

  defp execute_command({"approve", _}, _author, _params), do: Logger.info("Approve command")

  defp execute_command({"split", args}, _author, _params) when not is_nil(args) do
    case Regex.run(~r/@(\w+)\s+%(\d+)/, args) do
      [_, author, percentage] -> Logger.info("Split #{percentage}% with @#{author}")
      nil -> Logger.info("Invalid split format")
    end
  end

  defp execute_command({"claim", args}, _author, _params) when not is_nil(args) do
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

  defp execute_command({command, _}, _author, _params),
    do: Logger.info("Unhandled command: #{command}")

  def process_commands(body, author, params) when is_binary(body) do
    body |> extract_commands() |> Enum.map(&execute_command(&1, author, params))
  end

  def process_commands(_body, _author, _params), do: nil

  def extract_commands(body, regex \\ ~r{\B/(\w+)(?:\s+([^/\n]+))?}) do
    regex
    |> Regex.scan(body, capture: :all_but_first)
    |> Enum.map(fn
      [command] -> {command, nil}
      [command, args] -> {command, String.trim(args)}
    end)
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
