defmodule Algora.Github.Client do
  alias Joken
  alias Algora.Github
  alias Algora.Github.Crypto

  @type token :: String.t()

  def http(host, method, path, query, headers, body \\ "") do
    query_string = URI.encode_query([{:client_id, Github.client_id()} | query])
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

  def fetch(access_token, path, method \\ "GET") do
    http("api.github.com", method, path, [], [
      {"accept", "application/vnd.github.v3+json"},
      {"Authorization", "Bearer #{access_token}"}
    ])
  end

  def get_installation_token(installation_id) do
    with {:ok, jwt, _claims} <- Crypto.generate_jwt() do
      http("api.github.com", "POST", "/app/installations/#{installation_id}/access_tokens", [], [
        {"accept", "application/vnd.github.v3+json"},
        {"Authorization", "Bearer #{jwt}"}
      ])
    end
  end
end
