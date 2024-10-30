defmodule Algora.Admin do
  import Ecto.Query

  alias Algora.Repo
  alias Algora.Work
  alias Algora.Github
  alias Algora.Work.Repository

  @max_concurrency 1

  def token!(), do: System.fetch_env!("ADMIN_GITHUB_TOKEN")

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
    with {:ok, repo_data} <- Github.get(token!(), url),
         {:ok, repo} <- insert_or_update_repo(repo_data),
         :ok <- update_tasks(url, repo.id) do
      {:ok, repo}
    else
      error -> {:error, error}
    end
  end

  defp insert_or_update_repo(repo_data) do
    IO.puts("Inserting or updating repo #{repo_data["name"]}")

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
