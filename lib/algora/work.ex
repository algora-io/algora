defmodule Algora.Work do
  import Ecto.Query
  import Ecto.Changeset

  alias Algora.Work.Task
  alias Algora.Work.Repository
  alias Algora.Accounts.User
  alias Algora.Repo
  alias Algora.Github

  @spec upsert_task(
          provider :: atom(),
          %{
            token: Github.token(),
            owner: String.t(),
            repo: String.t(),
            number: integer(),
            type: atom(),
            meta: map()
          }
        ) ::
          {:ok, Task.t()} | {:error, atom()}
  def upsert_task(provider, %{
        token: token,
        owner: owner,
        repo: repo,
        type: type,
        meta: meta
      }) do
    with {:ok, user} <- fetch_user_by_handle(provider, %{token: token, handle: owner}),
         {:ok, repo} <-
           fetch_repository(provider, %{
             token: token,
             owner: owner,
             repo: repo
           }) do
      Task.changeset(provider, type, meta)
      |> put_change(:user_id, user.id)
      |> put_change(:repository_id, repo.id)
      |> Repo.insert(
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        conflict_target: [:provider, :provider_id]
      )
    end
  end

  @spec upsert_repository(:github, %{
          token: Github.token(),
          owner: String.t(),
          repo: String.t(),
          meta: map()
        }) ::
          {:ok, Repository.t()} | {:error, atom()}
  def upsert_repository(:github, %{token: token, meta: meta}) do
    with {:ok, user} <- fetch_user(:github, %{token: token, id: meta["owner"]["id"]}) do
      Repository.changeset(:github, meta)
      |> put_change(:user_id, user.id)
      |> Repo.insert(
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        conflict_target: [:provider, :provider_id]
      )
    end
  end

  @spec upsert_user(:github, %{meta: map()}) ::
          {:ok, User.t()} | {:error, atom()}
  def upsert_user(:github, %{meta: meta}) do
    User.external_user_changeset(:github, meta)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:provider, :provider_id]
    )
  end

  @spec fetch_task(:github, %{
          token: Github.token(),
          owner: String.t(),
          repo: String.t(),
          number: integer()
        }) ::
          {:ok, Task.t()} | {:error, atom()}
  def fetch_task(:github, %{token: token, owner: owner, repo: repo, number: number}) do
    query =
      from t in Task,
        join: r in assoc(t, :repository),
        where:
          t.provider == "github" and r.name == ^repo and r.owner == ^owner and t.number == ^number

    with nil <- Repo.one(query),
         {:ok, meta} <- Github.get_issue(token, owner, repo, number),
         {:ok, task} <-
           upsert_task(:github, %{
             token: token,
             owner: owner,
             repo: repo,
             number: number,
             meta: meta
           }) do
      {:ok, task}
    end
  end

  @spec fetch_user(:github, %{token: Github.token(), id: String.t()}) ::
          {:ok, User.t()} | {:error, atom()}
  def fetch_user(:github, %{token: token, id: id}) do
    query =
      from u in User,
        where: u.provider == "github" and u.provider_id == ^id

    with nil <- Repo.one(query),
         {:ok, meta} <- Github.get_user(token, id),
         {:ok, user} <- upsert_user(:github, %{meta: meta}) do
      {:ok, user}
    end
  end

  @spec fetch_user_by_handle(:github, %{token: Github.token(), handle: String.t()}) ::
          {:ok, User.t()} | {:error, atom()}
  def fetch_user_by_handle(:github, %{token: token, handle: handle}) do
    query =
      from u in User,
        where: u.provider == "github" and u.provider_login == ^handle

    with nil <- Repo.one(query),
         {:ok, meta} <- Github.get_user_by_username(token, handle),
         {:ok, user} <- upsert_user(:github, %{meta: meta}) do
      {:ok, user}
    end
  end

  @spec fetch_repository(:github, %{
          token: Github.token(),
          owner: String.t(),
          repo: String.t()
        }) ::
          {:ok, Repository.t()} | {:error, atom()}
  def fetch_repository(:github, %{token: token, owner: owner, repo: repo}) do
    query =
      from r in Repository,
        join: u in assoc(r, :user),
        where: r.provider == "github" and r.name == ^repo and u.provider_login == ^owner

    with nil <- Repo.one(query),
         {:ok, meta} <- Github.get_repository(token, owner, repo),
         {:ok, repo} <-
           upsert_repository(:github, %{token: token, owner: owner, repo: repo, meta: meta}) do
      {:ok, repo}
    end
  end

  def fetch_task_details(token, url) do
    case parse_url(url) do
      {:ok, %{"owner" => owner, "repo" => repo, "number" => number, "type" => :issue}} ->
        Github.get_issue(token, owner, repo, number)

      {:ok, %{"owner" => owner, "repo" => repo, "number" => number, "type" => :pull_request}} ->
        Github.get_pull_request(token, owner, repo, number)

      :error ->
        {:error, "Invalid GitHub URL"}
    end
  end

  defp parse_url(url) do
    cond do
      issue_params = parse_url(:github, :issue, url) ->
        {:ok, issue_params |> Map.put("type", :issue)}

      pr_params = parse_url(:github, :pull_request, url) ->
        {:ok, pr_params |> Map.put("type", :pull_request)}

      true ->
        :error
    end
  end

  defp parse_url(:github, :issue, url) do
    regex =
      ~r|https?://(?:www\.)?github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/issues/(?<number>\d+)|

    parse_with_regex(regex, url)
  end

  defp parse_url(:github, :pull_request, url) do
    regex =
      ~r|https?://(?:www\.)?github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/pull/(?<number>\d+)|

    parse_with_regex(regex, url)
  end

  defp parse_with_regex(regex, url) do
    case Regex.named_captures(regex, url) do
      %{"owner" => _owner, "repo" => _repo, "number" => _number} = params ->
        params

      nil ->
        nil
    end
  end
end
