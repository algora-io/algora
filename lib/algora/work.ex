defmodule Algora.Work do
  import Ecto.Query

  alias Algora.Work.Task
  alias Algora.Work.Repository
  alias Algora.Accounts.User
  alias Algora.Repo
  alias Algora.Github

  @upsert_options [
    on_conflict: {:replace_all_except, [:id, :inserted_at]},
    conflict_target: [:provider, :provider_id]
  ]

  @type task_type :: :issue | :pull_request

  @spec upsert_task(
          :github,
          %{
            token: Github.token(),
            owner: String.t(),
            repo: String.t(),
            number: integer(),
            meta: map()
          }
        ) ::
          {:ok, Task.t()} | {:error, atom()}
  def upsert_task(:github, %{
        token: token,
        owner: owner,
        repo: repo,
        meta: meta
      }) do
    with {:ok, repo} <- fetch_repository(:github, %{token: token, owner: owner, repo: repo}) do
      Task.github_changeset(repo, meta)
      |> Repo.insert(@upsert_options)
    end
  end

  @spec upsert_repository(:github, %{token: Github.token(), owner: String.t(), meta: map()}) ::
          {:ok, Repository.t()} | {:error, atom()}
  def upsert_repository(:github, %{token: token, owner: owner, meta: meta}) do
    with {:ok, user} <- fetch_user(:github, %{token: token, login: owner}) do
      Repository.github_changeset(user, meta)
      |> Repo.insert(@upsert_options)
    end
  end

  @spec upsert_user(:github, %{meta: map()}) :: {:ok, User.t()} | {:error, atom()}
  def upsert_user(:github, %{meta: meta}) do
    User.github_changeset(meta)
    |> Repo.insert(@upsert_options)
  end

  @spec fetch_task(:github, %{
          token: Github.token(),
          owner: String.t(),
          repo: String.t(),
          number: integer()
        }) :: {:ok, Task.t()} | {:error, atom()}
  def fetch_task(:github, %{token: token, owner: owner, repo: repo, number: number}) do
    query =
      from t in Task,
        join: r in assoc(t, :repository),
        join: u in assoc(r, :user),
        where:
          t.provider == "github" and
            u.provider_login == ^owner and
            r.name == ^repo and
            t.number == ^number

    with nil <- Repo.one(query),
         {:ok, meta} <- Github.get_issue(token, owner, repo, number) do
      upsert_task(:github, %{token: token, owner: owner, repo: repo, number: number, meta: meta})
    end
  end

  @spec fetch_user(:github, %{token: Github.token(), id: String.t()}) ::
          {:ok, User.t()} | {:error, atom()}
  def fetch_user(:github, %{token: token, id: id}) do
    query =
      from u in User,
        where: u.provider == "github" and u.provider_id == ^id

    with nil <- Repo.one(query),
         {:ok, meta} <- Github.get_user(token, id) do
      upsert_user(:github, %{meta: meta})
    end
  end

  @spec fetch_user(:github, %{token: Github.token(), login: String.t()}) ::
          {:ok, User.t()} | {:error, atom()}
  def fetch_user(:github, %{token: token, login: login}) do
    query =
      from u in User,
        where: u.provider == "github" and u.provider_login == ^login

    with nil <- Repo.one(query),
         {:ok, meta} <- Github.get_user_by_username(token, login) do
      upsert_user(:github, %{meta: meta})
    end
  end

  @spec fetch_repository(:github, %{token: Github.token(), owner: String.t(), repo: String.t()}) ::
          {:ok, Repository.t()} | {:error, atom()}
  def fetch_repository(:github, %{token: token, owner: owner, repo: repo}) do
    query =
      from r in Repository,
        join: u in assoc(r, :user),
        where: r.provider == "github" and r.name == ^repo and u.provider_login == ^owner

    with nil <- Repo.one(query),
         {:ok, meta} <- Github.get_repository(token, owner, repo) do
      upsert_repository(:github, %{token: token, owner: owner, meta: meta})
    end
  end
end
