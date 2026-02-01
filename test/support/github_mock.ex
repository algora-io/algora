defmodule Algora.Support.GithubMock do
  @moduledoc false
  @behaviour Algora.Github.Behaviour

  defp random_id(n \\ 1000), do: :rand.uniform(n)

  @impl true
  def get_delivery(id) do
    {:ok, %{"id" => id}}
  end

  @impl true
  def list_deliveries(_opts \\ []) do
    {:ok, []}
  end

  @impl true
  def redeliver(_id) do
    {:ok, %{"id" => random_id()}}
  end

  @impl true
  def get_issue(_access_token, owner, repo, number) do
    {:ok,
     %{
       "id" => random_id(),
       "title" => "title #{number}",
       "body" => "body #{number}",
       "number" => number,
       "html_url" => "https://github.com/#{owner}/#{repo}/issues/#{number}",
       "state" => "open"
     }}
  end

  @impl true
  def get_repository(_access_token, owner, repo) do
    {:ok,
     %{
       "id" => random_id(),
       "name" => repo,
       "html_url" => "https://github.com/#{owner}/#{repo}",
       "owner" => %{
         "login" => owner
       },
       "stargazers_count" => 1337
     }}
  end

  @impl true
  def get_repository(_access_token, id) do
    owner = "owner_#{random_id()}"
    name = "repo_#{random_id()}"

    {:ok,
     %{
       "id" => id,
       "name" => name,
       "html_url" => "https://github.com/#{owner}/#{name}",
       "owner" => %{
         "login" => owner
       },
       "stargazers_count" => 1337
     }}
  end

  @impl true
  def get_pull_request(_access_token, owner, repo, number) do
    {:ok,
     %{
       "id" => random_id(),
       "title" => "title #{number}",
       "body" => "body #{number}",
       "number" => number,
       "html_url" => "https://github.com/#{owner}/#{repo}/pull/#{number}",
       "state" => "open"
     }}
  end

  @impl true
  def get_current_user(_access_token) do
    {:ok, %{"id" => random_id(), "login" => "user_#{random_id()}"}}
  end

  @impl true
  def get_current_user_emails(_access_token) do
    {:ok, [%{"email" => "user_#{random_id()}@example.com"}]}
  end

  @impl true
  def get_user(_access_token, id) do
    {:ok, %{"id" => id, "login" => "user_#{id}"}}
  end

  @impl true
  def get_user_by_username(_access_token, username) do
    {:ok, %{"id" => :erlang.phash2(username, 1_000_000) + 1_000_000, "login" => username}}
  end

  @impl true
  def get_repository_permissions(_access_token, _owner, _repo, username) do
    {:ok,
     %{
       "permission" =>
         case username do
           "admin" <> _ -> "admin"
           _ -> "none"
         end
     }}
  end

  @impl true
  def list_installations(_token, _page \\ 1) do
    {:ok, %{"installations" => []}}
  end

  @impl true
  def find_installation(_token, _installation_id, _page \\ 1) do
    {:ok, %{"id" => random_id()}}
  end

  @impl true
  def get_installation_token(_installation_id) do
    {:ok, %{"token" => "token_#{random_id()}"}}
  end

  @impl true
  def get_installation(_installation_id) do
    {:ok, %{"id" => random_id()}}
  end

  @impl true
  def list_installation_repos(_access_token) do
    {:ok, []}
  end

  @impl true
  def create_issue_comment(_access_token, _owner, _repo, _number, _body) do
    {:ok, %{"id" => random_id()}}
  end

  @impl true
  def update_issue_comment(_access_token, _owner, _repo, _comment_id, _body) do
    {:ok, %{"id" => random_id()}}
  end

  @impl true
  def delete_issue_comment(_access_token, _owner, _repo, _comment_id) do
    {:ok, %{"id" => random_id()}}
  end

  @impl true
  def list_user_repositories(_access_token, _username, _opts \\ []) do
    {:ok, []}
  end

  @impl true
  def list_repository_events(_access_token, _owner, _repo, _opts \\ []) do
    {:ok, []}
  end

  @impl true
  def list_repository_comments(_access_token, _owner, _repo, _opts \\ []) do
    {:ok, []}
  end

  @impl true
  def list_repository_languages(_access_token, _owner, _repo) do
    {:ok, []}
  end

  @impl true
  def list_repository_contributors(_access_token, _owner, _repo) do
    {:ok, []}
  end

  @impl true
  def add_labels(_access_token, _owner, _repo, _number, _labels) do
    {:ok, []}
  end

  @impl true
  def list_labels(_access_token, _owner, _repo, _number) do
    {:ok, []}
  end

  @impl true
  def create_label(_access_token, _owner, _repo, _label) do
    {:ok, %{"id" => random_id()}}
  end

  @impl true
  def get_label(_access_token, _owner, _repo, _label) do
    {:ok, %{"id" => random_id()}}
  end

  @impl true
  def remove_label(_access_token, _owner, _repo, _label) do
    {:ok, %{"id" => random_id()}}
  end

  @impl true
  def remove_label_from_issue(_access_token, _owner, _repo, _number, _label) do
    {:ok, %{"id" => random_id()}}
  end

  @impl true
  def list_user_followers(_access_token, _username, _opts \\ []) do
    {:ok, []}
  end

  @impl true
  def list_user_following(_access_token, _username, _opts \\ []) do
    {:ok, []}
  end
end
