defmodule Algora.Admin do
  import Ecto.Query

  alias Algora.Repo
  alias Algora.Accounts.Identity
  alias Algora.Work
  alias Algora.Work.Repository

  @max_concurrency 1

  def token!() do
    with identity when not is_nil(identity) <-
           Identity
           |> where([i], i.provider == "github")
           |> limit(1)
           |> Repo.one() do
      identity.provider_token
    else
      _ -> nil
    end
  end

  def backfill_repos!() do
    query =
      from t in Algora.Work.Task,
        where: fragment("?->>'repository_url' IS NOT NULL", t.provider_meta),
        group_by: fragment("?->>'repository_url'", t.provider_meta),
        order_by: [desc: count()],
        select: %{repository_url: fragment("?->>'repository_url'", t.provider_meta)}

    Repo.all(query)
    |> Task.async_stream(fn %{repository_url: url} -> process_repo(url) end,
      max_concurrency: @max_concurrency,
      timeout: :infinity
    )
    |> Stream.run()
  end

  defp process_repo(url) do
    with {:ok, repo_data} <- fetch_or_load_repo_data(url),
         {:ok, repo} <- insert_or_update_repo(repo_data),
         :ok <- update_tasks(url, repo.id) do
      {:ok, repo}
    else
      error -> {:error, error}
    end
  end

  defp fetch_or_load_repo_data(url) do
    hash = :crypto.hash(:sha256, url) |> Base.encode16(case: :lower)
    cache_path = ".local/github/#{hash}.json"

    if File.exists?(cache_path) do
      File.read!(cache_path) |> Jason.decode()
    else
      res =
        Finch.build(:get, url, [
          {"Authorization", "Bearer #{token!()}"},
          {"accept", "application/vnd.github.v3+json"},
          {"Content-Type", "application/json"}
        ])
        |> Finch.request(Algora.Finch)

      with {:ok, %Finch.Response{status: 200, body: body}} <- res,
           {:ok, repo_data} <- Jason.decode(body) do
        File.mkdir_p!(Path.dirname(cache_path))
        File.write!(cache_path, Jason.encode!(repo_data))
        {:ok, repo_data}
      else
        {:ok, %Finch.Response{status: status}} ->
          {:error, "GitHub API returned status #{status}"}

        error ->
          {:error, "Failed to fetch repository data: #{inspect(error)}"}
      end
    end
  end

  defp insert_or_update_repo(repo_data) do
    dbg(repo_data["html_url"])

    with {:ok, user} <-
           Work.fetch_user(:github, %{token: token!(), id: repo_data["owner"]["id"]}),
         repo <- Repo.get_by(Repository, provider_id: to_string(repo_data["id"])) do
      unless repo do
        Repository.github_changeset(user, repo_data)
        |> Repo.insert_or_update()
      end
    else
      error -> {:error, "Failed to fetch or process user: #{inspect(error)}"}
    end
  end

  defp update_tasks(url, repo_id) do
    from(t in Algora.Work.Task,
      where: fragment("?->>'repository_url' = ?", t.provider_meta, ^url)
    )
    |> Repo.update_all(set: [repository_id: repo_id])

    :ok
  end
end
