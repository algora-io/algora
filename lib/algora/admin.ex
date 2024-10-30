defmodule Algora.Admin do
  import Ecto.Query

  alias Algora.Repo
  alias Algora.Work

  @max_concurrency 1

  def token!(), do: System.fetch_env!("ADMIN_GITHUB_TOKEN")

  def backfill_repos!() do
    query =
      from(t in Algora.Work.Task,
        where: fragment("?->>'repository_url' IS NOT NULL", t.provider_meta),
        distinct: fragment("?->>'repository_url'", t.provider_meta),
        select: fragment("?->>'repository_url'", t.provider_meta)
      )

    {success, failure} =
      Repo.all(query)
      |> Stream.map(&repo_params/1)
      |> Task.async_stream(
        fn
          {:ok, %{owner: owner, repo: repo}} ->
            case Work.fetch_repository(:github, %{token: token!(), owner: owner, repo: repo}) do
              {:ok, _} -> {:success}
              {:error, _} -> {:failure}
            end

          {:error, _} = _error ->
            {:failure}
        end,
        max_concurrency: @max_concurrency,
        timeout: :infinity
      )
      |> Enum.reduce({0, 0}, fn
        {:ok, {:success}}, {s, f} -> {s + 1, f}
        {:ok, {:failure}}, {s, f} -> {s, f + 1}
        {:exit, _}, {s, f} -> {s, f + 1}
      end)

    IO.puts("Repository backfill complete: #{success} succeeded, #{failure} failed")
    :ok
  end

  def repo_params(url) do
    with %URI{host: "api.github.com", path: "/repos/" <> path} <- URI.parse(url),
         [owner, repo] <- String.split(path, "/", trim: true) do
      {:ok, %{owner: owner, repo: repo}}
    else
      _ -> {:error, :invalid_github_url}
    end
  end
end
