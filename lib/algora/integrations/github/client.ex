defmodule Algora.Github.Client do
  @moduledoc false
  @behaviour Algora.Github.Behaviour

  alias Algora.Github.Crypto

  @type token :: String.t()

  # TODO: move to a separate module and use only for data migration between databases
  def http_cached(host, method, path, headers, body, opts \\ []) do
    cache_path = ".local/github/#{path}.json"

    with :error <- read_from_cache(cache_path),
         {:ok, response_body} <- do_http_request(host, method, path, headers, body, opts) do
      write_to_cache(cache_path, response_body)
      {:ok, response_body}
    else
      {:ok, cached_data} -> {:ok, cached_data}
      {:error, reason} -> {:error, reason}
    end
  end

  def http(host, method, path, headers, body, opts \\ []) do
    do_http_request(host, method, path, headers, body, opts)
  end

  defp do_http_request(host, method, path, headers, body, opts) do
    url = "https://#{host}#{path}"
    headers = [{"Content-Type", "application/json"} | headers]

    with {:ok, encoded_body} <- Jason.encode(body),
         request = Finch.build(method, url, headers, encoded_body),
         {:ok, response} <- Finch.request(request, Algora.Finch) do
      if opts[:skip_decoding], do: {:ok, response.body}, else: handle_response(response)
    end
  end

  defp handle_response(%Finch.Response{body: body}) do
    case Jason.decode(body) do
      {:ok, decoded_body} -> maybe_handle_error(decoded_body)
      {:error, reason} -> {:error, reason}
    end
  end

  defp maybe_handle_error(%{"message" => message, "status" => status} = body) do
    case Integer.parse(status) do
      {code, _} when code >= 400 -> {:error, "#{code} #{message}"}
      _ -> {:ok, body}
    end
  end

  defp maybe_handle_error(body), do: {:ok, body}

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

  def fetch(access_token, url, method \\ "GET", body \\ nil, opts \\ [])

  def fetch(access_token, "https://api.github.com" <> path, method, body, opts),
    do: fetch(access_token, path, method, body, opts)

  def fetch(access_token, path, method, body, opts) do
    http(
      "api.github.com",
      method,
      path,
      [{"accept", "application/vnd.github.v3+json"}, {"Authorization", "Bearer #{access_token}"}],
      body,
      opts
    )
  end

  defp build_query(opts), do: if(opts == [], do: "", else: "?" <> URI.encode_query(opts))

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

    with {:ok, jwt, _claims} <- Crypto.generate_jwt(),
         {:ok, %{"token" => token}} <- fetch(jwt, path, "POST") do
      {:ok, token}
    end
  end

  @impl true
  def create_issue_comment(access_token, owner, repo, number, body) do
    fetch(
      access_token,
      "/repos/#{owner}/#{repo}/issues/#{number}/comments",
      "POST",
      %{body: body}
    )
  end

  @impl true
  def list_repository_events(access_token, owner, repo, opts \\ []) do
    fetch(access_token, "/repos/#{owner}/#{repo}/events#{build_query(opts)}")
  end

  @impl true
  def list_repository_comments(access_token, owner, repo, opts \\ []) do
    fetch(access_token, "/repos/#{owner}/#{repo}/issues/comments#{build_query(opts)}")
  end

  @impl true
  def add_labels(access_token, owner, repo, number, labels) do
    fetch(access_token, "/repos/#{owner}/#{repo}/issues/#{number}/labels", "POST", %{labels: labels})
  end

  @impl true
  def render_markdown(access_token, markdown) do
    fetch(access_token, "/markdown", "POST", %{text: markdown}, skip_decoding: true)
  end
end
