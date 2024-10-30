defmodule Algora.Github do
  import Algora.Github.Client, only: [fetch: 2]

  @type token :: String.t()

  def client_id, do: Algora.config([:github, :client_id])
  def secret, do: Algora.config([:github, :client_secret])
  def app_handle, do: Algora.config([:github, :app_handle])
  def app_id, do: Algora.config([:github, :app_id])
  def webhook_secret, do: Algora.config([:github, :webhook_secret])
  def private_key, do: Algora.config([:github, :private_key])

  def install_url() do
    "https://github.com/apps/#{app_handle()}/installations/new"
  end

  def authorize_url(return_to \\ nil) do
    redirect_query = if return_to, do: URI.encode_query(return_to: return_to)

    query =
      URI.encode_query(
        client_id: client_id(),
        state: Algora.Util.random_string(),
        redirect_uri: "#{AlgoraWeb.Endpoint.url()}/callbacks/github/oauth?#{redirect_query}"
      )

    "https://github.com/login/oauth/authorize?#{query}"
  end

  def get(access_token, url) do
    fetch(access_token, url)
  end

  def get_issue(access_token, owner, repo, number) do
    fetch(access_token, "/repos/#{owner}/#{repo}/issues/#{number}")
  end

  def get_repository(access_token, owner, repo) do
    fetch(access_token, "/repos/#{owner}/#{repo}")
  end

  def get_repository(access_token, id) do
    fetch(access_token, "/repositories/#{id}")
  end

  def get_pull_request(access_token, owner, repo, number) do
    fetch(access_token, "/repos/#{owner}/#{repo}/pulls/#{number}")
  end

  def get_current_user(access_token) do
    fetch(access_token, "/user")
  end

  def get_current_user_emails(access_token) do
    fetch(access_token, "/user/emails")
  end

  def get_user(access_token, id) do
    fetch(access_token, "/user/#{id}")
  end

  def get_user_by_username(access_token, username) do
    fetch(access_token, "/users/#{username}")
  end

  def list_installations(token, page \\ 1) do
    fetch(token, "/user/installations?page=#{page}")
  end

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
end
