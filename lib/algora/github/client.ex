defmodule Algora.Github.Client do
  @behaviour Algora.Github.Behaviour

  alias Joken
  alias Algora.Github.Crypto

  @type token :: String.t()

  def http(host, method, path, headers, body \\ "") do
    cache_path = ".local/github/#{path}.json"
    url = "https://#{host}#{path}"

    case read_from_cache(cache_path) do
      {:ok, cached_data} ->
        {:ok, cached_data}

      :error ->
        headers = [{"Content-Type", "application/json"} | headers]
        request = Finch.build(method, url, headers, body)

        case Finch.request(request, Algora.Finch) do
          {:ok, %Finch.Response{status: 200, body: body}} ->
            decoded_body = Jason.decode!(body)
            write_to_cache(cache_path, decoded_body)
            {:ok, decoded_body}

          {:ok, %Finch.Response{body: body}} ->
            {:ok, Jason.decode!(body)}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp read_from_cache(cache_path) do
    if File.exists?(cache_path) do
      case File.read(cache_path) do
        {:ok, content} -> Jason.decode(content)
        {:error, _} -> :error
      end
    else
      :error
    end
  end

  defp write_to_cache(cache_path, data) do
    File.mkdir_p!(Path.dirname(cache_path))
    File.write!(cache_path, Jason.encode!(data))
  end

  def fetch(access_token, url, method \\ "GET", body \\ "")

  def fetch(access_token, "https://api.github.com" <> path, method, body),
    do: fetch(access_token, path, method, body)

  def fetch(access_token, path, method, body) do
    http(
      "api.github.com",
      method,
      path,
      [{"accept", "application/vnd.github.v3+json"}, {"Authorization", "Bearer #{access_token}"}],
      body
    )
  end

  @impl true
  def get_issue(access_token, owner, repo, number) do
    fetch(access_token, "/repos/#{owner}/#{repo}/issues/#{number}")
  end

  @impl true
  def get_repository(access_token, owner, repo) do
    fetch(access_token, "/repos/#{owner}/#{repo}")
  end

  @impl true
  def get_repository(access_token, id) do
    fetch(access_token, "/repositories/#{id}")
  end

  @impl true
  def get_pull_request(access_token, owner, repo, number) do
    fetch(access_token, "/repos/#{owner}/#{repo}/pulls/#{number}")
  end

  @impl true
  def get_current_user(access_token) do
    fetch(access_token, "/user")
  end

  @impl true
  def get_current_user_emails(access_token) do
    fetch(access_token, "/user/emails")
  end

  @impl true
  def get_user(access_token, id) do
    fetch(access_token, "/user/#{id}")
  end

  @impl true
  def get_user_by_username(access_token, username) do
    fetch(access_token, "/users/#{username}")
  end

  @impl true
  def get_repository_permissions(access_token, owner, repo, username) do
    fetch(access_token, "/repos/#{owner}/#{repo}/collaborators/#{username}/permission")
  end

  @impl true
  def list_installations(token, page \\ 1) do
    fetch(token, "/user/installations?page=#{page}")
  end

  @impl true
  def find_installation(token, installation_id, page \\ 1) do
    case list_installations(token, page) do
      {:ok, %{"installations" => installations}} ->
        find_installation_in_list(token, installation_id, installations, page)

      {:error, _reason} = error ->
        error
    end
  end

  defp find_installation_in_list(token, installation_id, installations, page) do
    case Enum.find(installations, fn i -> i["id"] == installation_id end) do
      nil -> find_installation(token, installation_id, page + 1)
      installation -> {:ok, installation}
    end
  end

  @impl true
  def get_installation_token(installation_id) do
    path = "/app/installations/#{installation_id}/access_tokens"

    case Crypto.generate_jwt() do
      {:ok, jwt, _claims} -> fetch(jwt, path, "POST")
      error -> error
    end
  end

  @impl true
  def create_issue_comment(access_token, owner, repo, number, body) do
    fetch(access_token, "/repos/#{owner}/#{repo}/issues/#{number}/comments", "POST", body)
  end
end
