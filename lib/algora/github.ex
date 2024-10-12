defmodule Algora.Github do
  # TODO: Make this dynamic
  defp app_slug, do: "algora-dev"

  def install_url() do
    "https://github.com/apps/#{app_slug()}/installations/new"
  end

  def authorize_url(return_to \\ nil) do
    redirect_query = if return_to, do: URI.encode_query(return_to: return_to)

    query =
      URI.encode_query(
        client_id: client_id(),
        state: Algora.Util.random_string(),
        scope: "user:email",
        redirect_uri: "#{AlgoraWeb.Endpoint.url()}/oauth/callbacks/github?#{redirect_query}"
      )

    "https://github.com/login/oauth/authorize?#{query}"
  end

  def exchange_access_token(opts) do
    code = Keyword.fetch!(opts, :code)
    state = Keyword.fetch!(opts, :state)

    state
    |> fetch_exchange_response(code)
    |> fetch_user_info()
    |> fetch_emails()
  end

  defp fetch_exchange_response(state, code) do
    resp =
      http(
        "github.com",
        "POST",
        "/login/oauth/access_token",
        [state: state, code: code, client_secret: secret()],
        [{"accept", "application/json"}]
      )

    with {:ok, resp} <- resp,
         %{"access_token" => token} <- Jason.decode!(resp) do
      {:ok, token}
    else
      {:error, _reason} = err -> err
      %{} = resp -> {:error, {:bad_response, resp}}
    end
  end

  def fetch(access_token, path, method \\ "GET") do
    http("api.github.com", method, path, [], [
      {"accept", "application/vnd.github.v3+json"},
      {"Authorization", "token #{access_token}"}
    ])
  end

  defp fetch_user_info({:error, _reason} = error), do: error

  defp fetch_user_info({:ok, token}) do
    resp = fetch(token, "/user")

    case resp do
      {:ok, info} -> {:ok, %{info: Jason.decode!(info), token: token}}
      {:error, _reason} = err -> err
    end
  end

  defp fetch_emails({:error, _} = err), do: err

  defp fetch_emails({:ok, user}) do
    resp = fetch(user.token, "/user/emails")

    case resp do
      {:ok, info} ->
        emails = Jason.decode!(info)
        {:ok, Map.merge(user, %{primary_email: primary_email(emails), emails: emails})}

      {:error, _reason} = err ->
        err
    end
  end

  def get_user_by_username(access_token, username) do
    fetch(access_token, "/users/#{username}")
  end

  def find_installation(access_token, installation_id) do
    fetch(access_token, "/user/installations/#{installation_id}")
  end

  defp client_id, do: Algora.config([:github, :client_id])
  defp secret, do: Algora.config([:github, :client_secret])

  defp http(host, method, path, query, headers, body \\ "") do
    query_string = URI.encode_query([{:client_id, client_id()} | query])
    url = "https://#{host}#{path}?#{query_string}"

    headers = [{"Content-Type", "application/json"} | headers]

    request = Finch.build(method, url, headers, body)

    case Finch.request(request, Algora.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Finch.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp primary_email(emails) do
    Enum.find(emails, fn email -> email["primary"] end)["email"] || Enum.at(emails, 0)
  end
end
