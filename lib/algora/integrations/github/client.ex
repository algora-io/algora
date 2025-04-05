defmodule Algora.Github.Client do
  @moduledoc false
  @behaviour Algora.Github.Behaviour

  alias Algora.Github.Crypto

  require Logger

  @type token :: String.t()

  def http(host, method, path, headers, body) do
    do_http_request(host, method, path, headers, body)
  end

  defp do_http_request(host, method, path, headers, body) do
    url = "https://#{host}#{path}"
    headers = [{"Content-Type", "application/json"} | headers]

    with {:ok, encoded_body} <- Jason.encode(body),
         request = Finch.build(method, url, headers, encoded_body),
         {:ok, %Finch.Response{body: body}} <- request_with_follow_redirects(request),
         {:ok, decoded_body} <- Jason.decode(body) do
      maybe_handle_error(decoded_body)
    end
  end

  defp request_with_follow_redirects(request) do
    case Finch.request(request, Algora.Finch) do
      {:ok, %Finch.Response{status: status, headers: headers}} when status in [301, 302, 307] ->
        case List.keyfind(headers, "location", 0) do
          {"location", location} ->
            request_with_follow_redirects(Finch.build(request.method, location, request.headers, request.body))

          nil ->
            {:error, "Redirect response missing location header"}
        end

      res ->
        res
    end
  end

  defp maybe_handle_error(%{"message" => message, "status" => status} = body) do
    case Integer.parse(status) do
      {code, _} when code >= 400 -> {:error, "#{code} #{message}"}
      _ -> {:ok, body}
    end
  end

  defp maybe_handle_error(body), do: {:ok, body}

  def run_cached(path, fun) do
    case read_from_cache(path) do
      :not_found ->
        Logger.warning("❌ Cache miss for #{path}")
        write_to_cache!(fun.(), path)

      res ->
        res
    end
  end

  defp get_cache_path(path), do: Path.join([:code.priv_dir(:algora), "github", path <> ".bin"])

  defp maybe_retry({:ok, %{"message" => "Moved Permanently"}}), do: :not_found
  defp maybe_retry({:ok, data}), do: {:ok, data}
  defp maybe_retry({:error, "404 Not Found"}), do: {:error, "404 Not Found"}
  defp maybe_retry(_error), do: :not_found

  def read_from_cache(path) do
    cache_path = get_cache_path(path)

    if File.exists?(cache_path) do
      case File.read(cache_path) do
        {:ok, content} ->
          content
          |> :erlang.binary_to_term()
          |> maybe_retry()

        {:error, _} ->
          :not_found
      end
    else
      :not_found
    end
  end

  defp write_to_cache!(data, path) do
    cache_path = get_cache_path(path)
    File.mkdir_p!(Path.dirname(cache_path))
    File.write!(cache_path, :erlang.term_to_binary(data))
    data
  end

  def fetch(access_token, url, method \\ "GET", body \\ nil)

  def fetch(access_token, "https://api.github.com" <> path, method, body), do: fetch(access_token, path, method, body)

  def fetch(access_token, path, method, body) do
    http(
      "api.github.com",
      method,
      path,
      [{"accept", "application/vnd.github.v3+json"}] ++
        if(access_token, do: [{"Authorization", "Bearer #{access_token}"}], else: []),
      body
    )
  end

  def fetch_with_jwt(path, method \\ "GET", body \\ nil) do
    with {:ok, jwt, _claims} <- Crypto.generate_jwt() do
      fetch(jwt, path, method, body)
    end
  end

  defp build_query(opts), do: if(opts == [], do: "", else: "?" <> URI.encode_query(opts))

  @impl true
  def get_delivery(delivery_id) do
    fetch_with_jwt("/app/hook/deliveries/#{delivery_id}")
  end

  @impl true
  def list_deliveries(opts \\ []) do
    fetch_with_jwt("/app/hook/deliveries#{build_query(opts)}")
  end

  @impl true
  def redeliver(delivery_id) do
    fetch_with_jwt("/app/hook/deliveries/#{delivery_id}/attempts", "POST")
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

      {:error, reason} ->
        Logger.error("❌ Failed to find installation #{installation_id}: #{inspect(reason)}")
        {:error, reason}
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
    with {:ok, %{"token" => token}} <- fetch_with_jwt("/app/installations/#{installation_id}/access_tokens", "POST") do
      {:ok, token}
    end
  end

  @impl true
  def get_installation(installation_id) do
    with {:ok, %{"token" => token}} <- fetch_with_jwt("/app/installations/#{installation_id}") do
      {:ok, token}
    end
  end

  @impl true
  def list_installation_repos(access_token) do
    with {:ok, %{"repositories" => repos}} <-
           fetch(access_token, "/installation/repositories", "GET") do
      {:ok, repos}
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
  def update_issue_comment(access_token, owner, repo, comment_id, body) do
    fetch(
      access_token,
      "/repos/#{owner}/#{repo}/issues/comments/#{comment_id}",
      "PATCH",
      %{body: body}
    )
  end

  @impl true
  def list_user_repositories(access_token, username, opts \\ []) do
    fetch(access_token, "/users/#{username}/repos#{build_query(opts)}")
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
  def list_repository_languages(access_token, owner, repo) do
    fetch(access_token, "/repos/#{owner}/#{repo}/languages")
  end

  @impl true
  def list_repository_contributors(access_token, owner, repo) do
    fetch(access_token, "/repos/#{owner}/#{repo}/contributors")
  end

  @impl true
  def add_labels(access_token, owner, repo, number, labels) do
    fetch(access_token, "/repos/#{owner}/#{repo}/issues/#{number}/labels", "POST", %{
      labels: labels
    })
  end

  @impl true
  def create_label(access_token, owner, repo, label) do
    fetch(access_token, "/repos/#{owner}/#{repo}/labels", "POST", label)
  end

  @impl true
  def get_label(access_token, owner, repo, label) do
    fetch(access_token, "/repos/#{owner}/#{repo}/labels/#{label}")
  end
end
