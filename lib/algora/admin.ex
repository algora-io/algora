defmodule Algora.Admin do
  require Logger

  import Ecto.Query

  alias Algora.Repo
  alias Algora.Workspace

  def token!(), do: System.fetch_env!("ADMIN_GITHUB_TOKEN")

  def read!(path) do
    {:ok, data} = read(path)
    data
  end

  def read(path) do
    with {:ok, content} <- File.read(Path.join(:code.priv_dir(:algora), path)),
         {:ok, data} <- Jason.decode(content) do
      {:ok, data}
    else
      error ->
        Logger.error("Failed to read #{path}: #{inspect(error)}")
        error
    end
  end

  def backfill_repos!() do
    query =
      from(t in Algora.Workspace.Ticket,
        where: fragment("?->>'repository_url' IS NOT NULL", t.provider_meta),
        distinct: fragment("?->>'repository_url'", t.provider_meta),
        select: fragment("?->>'repository_url'", t.provider_meta)
      )

    {success, failure} =
      Repo.all(query)
      |> Task.async_stream(&backfill_repo/1, max_concurrency: 1, timeout: :infinity)
      |> Enum.reduce({0, 0}, fn
        {:ok, {:ok, _}}, {s, f} -> {s + 1, f}
        {:ok, {:error, _}}, {s, f} -> {s, f + 1}
        {:exit, _}, {s, f} -> {s, f + 1}
      end)

    IO.puts("Repository backfill complete: #{success} succeeded, #{failure} failed")
    :ok
  end

  def backfill_repo(url) do
    with %URI{host: "api.github.com", path: "/repos/" <> path} <- URI.parse(url),
         [owner, repo] <- String.split(path, "/", trim: true),
         {:ok, repo} <- Workspace.ensure_repository(token!(), owner, repo),
         :ok <- update_tickets(url, repo.id) do
      {:ok, repo}
    else
      error ->
        Logger.error("Failed to backfill repo #{url}: #{inspect(error)}")
        {:error, error}
    end
  end

  defp update_tickets(url, repo_id) do
    from(t in Algora.Workspace.Ticket,
      where: fragment("?->>'repository_url' = ?", t.provider_meta, ^url)
    )
    |> Repo.update_all(set: [repository_id: repo_id])

    :ok
  end
end
