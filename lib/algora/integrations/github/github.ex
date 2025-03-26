defmodule Algora.Github do
  @moduledoc false
  @behaviour Algora.Github.Behaviour

  require Logger

  @type token :: String.t()

  def client_id, do: Algora.config([:github, :client_id])
  def secret, do: Algora.config([:github, :client_secret])
  def app_handle, do: Algora.config([:github, :app_handle])
  def app_id, do: Algora.config([:github, :app_id])
  def webhook_secret, do: Algora.config([:github, :webhook_secret])
  def private_key, do: [:github, :private_key] |> Algora.config() |> String.replace("\\n", "\n")
  def pat, do: Algora.config([:github, :pat])
  def pat_enabled, do: Algora.config([:github, :pat_enabled])
  def bot_handle, do: Algora.config([:github, :bot_handle])

  def install_url_base, do: "https://github.com/apps/#{app_handle()}/installations"
  def install_url_new, do: "#{install_url_base()}/new"
  def install_url_select_target, do: "#{install_url_base()}/select_target"

  defp oauth_state_ttl, do: Algora.config([:github, :oauth_state_ttl])
  defp oauth_state_salt, do: Algora.config([:github, :oauth_state_salt])

  def generate_oauth_state(data) do
    Phoenix.Token.sign(AlgoraWeb.Endpoint, oauth_state_salt(), data, max_age: oauth_state_ttl())
  end

  def verify_oauth_state(token) do
    Phoenix.Token.verify(AlgoraWeb.Endpoint, oauth_state_salt(), token, max_age: oauth_state_ttl())
  end

  def authorize_url(data \\ nil) do
    redirect_uri = "#{AlgoraWeb.Endpoint.url()}/callbacks/github/oauth"

    query =
      URI.encode_query(
        client_id: client_id(),
        state: generate_oauth_state(data),
        redirect_uri: redirect_uri
      )

    "https://github.com/login/oauth/authorize?#{query}"
  end

  defp client, do: Application.get_env(:algora, :github_client, Algora.Github.Client)

  def try_without_installation(function, args) do
    if pat_enabled() do
      apply(function, [pat() | args])
    else
      {_, module} = Function.info(function, :module)
      {_, name} = Function.info(function, :name)
      function_name = String.trim_leading("#{module}.#{name}", "Elixir.")

      formatted_args =
        Enum.map_join(args, ", ", fn
          arg when is_binary(arg) -> "\"#{arg}\""
          arg -> "#{arg}"
        end)

      Logger.warning("""
      App installation not found and GITHUB_PAT_ENABLED is false, skipping Github call:
      #{function_name}(#{formatted_args})
      """)
    end
  end

  @impl true
  def get_repository(token, owner, repo), do: client().get_repository(token, owner, repo)

  @impl true
  def get_repository(token, id), do: client().get_repository(token, id)

  @impl true
  def get_issue(token, owner, repo, number), do: client().get_issue(token, owner, repo, number)

  @impl true
  def get_pull_request(token, owner, repo, number), do: client().get_pull_request(token, owner, repo, number)

  @impl true
  def get_current_user(token), do: client().get_current_user(token)

  @impl true
  def get_current_user_emails(token), do: client().get_current_user_emails(token)

  @impl true
  def get_user(token, id), do: client().get_user(token, id)

  @impl true
  def get_user_by_username(token, username), do: client().get_user_by_username(token, username)

  @impl true
  def get_repository_permissions(token, owner, repo, username),
    do: client().get_repository_permissions(token, owner, repo, username)

  @impl true
  def list_installations(token, page \\ 1), do: client().list_installations(token, page)

  @impl true
  def find_installation(token, installation_id, page \\ 1), do: client().find_installation(token, installation_id, page)

  @impl true
  def get_installation_token(installation_id), do: client().get_installation_token(installation_id)

  @impl true
  def get_installation(installation_id), do: client().get_installation(installation_id)
  @impl true
  def list_installation_repos(token), do: client().list_installation_repos(token)

  @impl true
  def create_issue_comment(token, owner, repo, number, body),
    do: client().create_issue_comment(token, owner, repo, number, body)

  @impl true
  def update_issue_comment(token, owner, repo, comment_id, body),
    do: client().update_issue_comment(token, owner, repo, comment_id, body)

  @impl true
  def list_user_repositories(token, username, opts \\ []), do: client().list_user_repositories(token, username, opts)

  @impl true
  def list_repository_events(token, owner, repo, opts \\ []),
    do: client().list_repository_events(token, owner, repo, opts)

  @impl true
  def list_repository_comments(token, owner, repo, opts \\ []),
    do: client().list_repository_comments(token, owner, repo, opts)

  @impl true
  def list_repository_languages(token, owner, repo), do: client().list_repository_languages(token, owner, repo)
  @impl true
  def list_repository_contributors(token, owner, repo), do: client().list_repository_contributors(token, owner, repo)

  @impl true
  def add_labels(token, owner, repo, number, labels), do: client().add_labels(token, owner, repo, number, labels)
end
