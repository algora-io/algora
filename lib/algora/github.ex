defmodule Algora.Github do
  alias Joken

  @type token :: String.t()
  def install_url() do
    "https://github.com/apps/#{app_handle()}/installations/new"
  end

  def authorize_url(return_to \\ nil) do
    redirect_query = if return_to, do: URI.encode_query(return_to: return_to)

    query =
      URI.encode_query(
        client_id: client_id(),
        state: Algora.Util.random_string(),
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

    with {:ok, %{"access_token" => token}} <- resp do
      {:ok, token}
    else
      {:error, _reason} = err -> err
      %{} = resp -> {:error, {:bad_response, resp}}
    end
  end

  def fetch(access_token, path, method \\ "GET") do
    http("api.github.com", method, path, [], [
      {"accept", "application/vnd.github.v3+json"},
      {"Authorization", "Bearer #{access_token}"}
    ])
  end

  defp fetch_user_info({:error, _reason} = error), do: error

  defp fetch_user_info({:ok, token}) do
    resp = fetch(token, "/user")

    case resp do
      {:ok, info} -> {:ok, %{info: info, token: token}}
      {:error, _reason} = err -> err
    end
  end

  defp fetch_emails({:error, _} = err), do: err

  defp fetch_emails({:ok, user}) do
    resp = fetch(user.token, "/user/emails")

    case resp do
      {:ok, emails} ->
        {:ok, Map.merge(user, %{primary_email: primary_email(emails), emails: emails})}

      {:error, _reason} = err ->
        err
    end
  end

  def get_issue(access_token, owner, repo, number) do
    fetch(access_token, "/repos/#{owner}/#{repo}/issues/#{number}")
  end

  def get_repository(access_token, owner, repo) do
    fetch(access_token, "/repos/#{owner}/#{repo}")
  end

  def get_pull_request(access_token, owner, repo, number) do
    fetch(access_token, "/repos/#{owner}/#{repo}/pulls/#{number}")
  end

  def get_user(access_token, id) do
    fetch(access_token, "/user/#{id}")
  end

  def get_user_by_username(access_token, username) do
    fetch(access_token, "/users/#{username}")
  end

  def run(path) do
    with {:ok, jwt, _claims} <- generate_jwt() do
      http("api.github.com", "POST", path, [], [
        {"accept", "application/vnd.github.v3+json"},
        {"Authorization", "Bearer #{jwt}"}
      ])
    end
  end

  def get_installation_token(installation_id) do
    with {:ok, jwt, _claims} <- generate_jwt() do
      http("api.github.com", "POST", "/app/installations/#{installation_id}/access_tokens", [], [
        {"accept", "application/vnd.github.v3+json"},
        {"Authorization", "Bearer #{jwt}"}
      ])
    end
  end

  def list_installations(token, page \\ 1) do
    fetch(token, "/user/installations?page=#{page}")
  end

  def find_installation(token, installation_id, page \\ 1) do
    case list_installations(token, page) do
      {:ok, %{"installations" => installations}} ->
        case Enum.find(installations, fn i -> i["id"] == installation_id end) do
          nil -> find_installation(token, installation_id, page + 1)
          installation -> {:ok, installation}
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp client_id, do: Algora.config([:github, :client_id])
  defp secret, do: Algora.config([:github, :client_secret])
  defp app_handle, do: Algora.config([:github, :app_handle])
  # defp app_id, do: Algora.config([:github, :app_id])
  # defp webhook_secret, do: Algora.config([:github, :webhook_secret])
  defp private_key, do: Algora.config([:github, :private_key])

  defp http(host, method, path, query, headers, body \\ "") do
    query_string = URI.encode_query([{:client_id, client_id()} | query])
    url = "https://#{host}#{path}?#{query_string}"

    headers = [{"Content-Type", "application/json"} | headers]

    request = Finch.build(method, url, headers, body)

    case Finch.request(request, Algora.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Finch.Response{body: body}} ->
        {:ok, Jason.decode!(body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp primary_email(emails) do
    Enum.find(emails, fn email -> email["primary"] end)["email"] || Enum.at(emails, 0)
  end

  @doc """
  Generates a JWT (JSON Web Token) for GitHub App authentication.

  ## Returns

  `{:ok, jwt, claims}` on success, `{:error, reason}` on failure
  """
  @spec generate_jwt() :: {:ok, String.t(), map()} | {:error, any()}
  def generate_jwt() do
    payload = %{
      "iat" => System.system_time(:second),
      "exp" => System.system_time(:second) + 600,
      "iss" => client_id()
    }

    signer = Joken.Signer.create("RS256", %{"pem" => private_key()})

    case Joken.generate_and_sign(%{}, payload, signer) do
      {:ok, token, claims} -> {:ok, token, claims}
      {:error, reason} -> {:error, reason}
    end
  end
end
