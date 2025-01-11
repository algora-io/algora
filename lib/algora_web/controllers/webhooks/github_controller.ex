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
    case Webhook.new(conn) do
      {:ok, %Webhook{delivery: _delivery, event: event, installation_id: _installation_id}} ->
        author = get_author(event, params)
        body = get_body(event, params)
        process_commands(body, author, params)

        conn |> put_status(:accepted) |> json(%{status: "ok"})

      {:error, :missing_header} ->
        conn |> put_status(:bad_request) |> json(%{error: "Missing header"})

      {:error, :signature_mismatch} ->
        conn |> put_status(:unauthorized) |> json(%{error: "Signature mismatch"})
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

  defp execute_command({:bounty, args}, author, params) do
    amount = args[:amount]
    repo = params["repository"]
    issue = params["issue"]
    installation_id = params["installation"]["id"]

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
        installation_id: installation_id
      )
    else
      {:ok, _permission} ->
        {:error, :unauthorized}

      {:error, _reason} = error ->
        error
    end
  end

  defp execute_command({:tip, args}, _author, _params) when not is_nil(args) do
    amount = Keyword.get(args, :amount)
    recipient = Keyword.get(args, :username)

    Logger.info("Tip #{amount} to #{recipient}")
  end

  defp execute_command({:claim, args}, _author, _params) when not is_nil(args) do
    owner = Keyword.get(args, :owner)
    repo = Keyword.get(args, :repo)
    number = Keyword.get(args, :number)

    Logger.info("Claim #{owner}/#{repo}##{number}")
  end

  defp execute_command({command, _} = args, _author, _params),
    do: Logger.info("Unhandled command: #{command} #{inspect(args)}")

  def process_commands(body, author, params) when is_binary(body) do
    case Github.Command.parse(body) do
      {:ok, commands} -> Enum.map(commands, &execute_command(&1, author, params))
      # TODO: handle errors
      {:error, error} -> Logger.error("Error parsing commands: #{inspect(error)}")
    end
  end

  def process_commands(_body, _author, _params), do: nil

  defp get_author("issues", params), do: params["issue"]["user"]
  defp get_author("issue_comment", params), do: params["comment"]["user"]
  defp get_author("pull_request", params), do: params["pull_request"]["user"]
  defp get_author(_event, _params), do: nil

  defp get_body("issues", params), do: params["issue"]["body"]
  defp get_body("issue_comment", params), do: params["comment"]["body"]
  defp get_body("pull_request", params), do: params["pull_request"]["body"]
  defp get_body(_event, _params), do: nil
end
