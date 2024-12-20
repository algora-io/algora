defmodule Mix.Tasks.DomainBlacklist do
  @moduledoc "The domain_blacklist mix task: `mix help domain_blacklist`"
  use Mix.Task
  require Logger

  @blacklist_url "https://gist.githubusercontent.com/okutbay/5b4974b70673dfdcc21c517632c1f984/raw/free_email_provider_domains.txt"

  @shortdoc "Update the free email provider domain list"
  def run(_) do
    :application.ensure_all_started(:finch)

    Finch.start_link(name: :blacklist)
    path = Path.join(:code.priv_dir(:algora), "domain_blacklist.txt")
    {{y,m,d}, _time} = :calendar.local_time
    case File.stat(path) do
      {:ok, %{mtime: {{my,mm,md} = mdate, _mtime}}} when my < y or mm < m or md + 7 < d ->
        Logger.info("Updating domain blacklist, last update #{inspect(mdate)}")
        update!(path)
      {:ok, _state} ->
        :ok
      {:error, :enoent} ->
        Logger.info("Downloading domain blacklist")
        update!(path)
      {:error, reason} ->
        Logger.error("Error when stating domain blacklist #{reason}")
    end
  end

  defp update!(path) do
    case Finch.build(:get, @blacklist_url) |> Finch.request(:blacklist) do
      {:ok, resp} ->
        File.write(path, resp.body)
        Logger.info("Wrote domain blacklist to #{inspect(path)}")
      {:error, reason} ->
        Logger.error("Failed to update blacklist #{inspect(reason)}")
    end
  end
end
