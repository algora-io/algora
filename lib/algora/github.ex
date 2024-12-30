defmodule Algora.Github do
  @behaviour Algora.Github.Behaviour

  @type token :: String.t()

  def client_id, do: Algora.config([:github, :client_id])
  def secret, do: Algora.config([:github, :client_secret])
  def app_handle, do: Algora.config([:github, :app_handle])
  def app_id, do: Algora.config([:github, :app_id])
  def webhook_secret, do: Algora.config([:github, :webhook_secret])
  def private_key, do: Algora.config([:github, :private_key]) |> String.replace("\\n", "\n")
  def pat, do: Algora.config([:github, :pat])
  def pat_enabled, do: Algora.config([:github, :pat_enabled])

  def install_url() do
    "https://github.com/apps/#{app_handle()}/installations/new"
  end

  def authorize_url(return_to \\ nil) do
    # TODO: find out a way to set return_to w/o github complaining about redirect_uri mismatch

    # redirect_query = if return_to, do: URI.encode_query(return_to: return_to)
    # redirect_uri = "#{AlgoraWeb.Endpoint.url()}/callbacks/github/oauth?#{redirect_query}"

    redirect_uri = "#{AlgoraWeb.Endpoint.url()}/callbacks/github/oauth"

    query =
      URI.encode_query(
        client_id: client_id(),
        state: Algora.Util.random_string(),
        redirect_uri: redirect_uri
      )

    "https://github.com/login/oauth/authorize?#{query}"
  end

  defp client, do: Application.get_env(:algora, :github_client, Algora.Github.Client)

  @impl true
  def get_repository(token, owner, repo),
    do: client().get_repository(token, owner, repo)

  @impl true
  def get_repository(token, id),
    do: client().get_repository(token, id)

  @impl true
  def get_issue(token, owner, repo, number),
    do: client().get_issue(token, owner, repo, number)

  @impl true
  def get_pull_request(token, owner, repo, number),
    do: client().get_pull_request(token, owner, repo, number)

  @impl true
  def get_current_user(token),
    do: client().get_current_user(token)

  @impl true
  def get_current_user_emails(token),
    do: client().get_current_user_emails(token)

  @impl true
  def get_user(token, id),
    do: client().get_user(token, id)

  @impl true
  def get_user_by_username(token, username),
    do: client().get_user_by_username(token, username)

  @impl true
  def get_repository_permissions(token, owner, repo, username),
    do: client().get_repository_permissions(token, owner, repo, username)

  @impl true
  def list_installations(token, page \\ 1),
    do: client().list_installations(token, page)

  @impl true
  def find_installation(token, installation_id, page \\ 1),
    do: client().find_installation(token, installation_id, page)

  @impl true
  def get_installation_token(installation_id),
    do: client().get_installation_token(installation_id)

  @impl true
  def create_issue_comment(token, owner, repo, number, body),
    do: client().create_issue_comment(token, owner, repo, number, body)

  @impl true
  def list_repository_events(token, owner, repo, opts \\ []),
    do: client().list_repository_events(token, owner, repo, opts)

  @impl true
  def list_repository_comments(token, owner, repo, opts \\ []),
    do: client().list_repository_comments(token, owner, repo, opts)
end
