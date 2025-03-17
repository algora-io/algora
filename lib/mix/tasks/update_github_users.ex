defmodule Mix.Tasks.UpdateGithubUsers do
  @shortdoc "Updates user data from GitHub"

  @moduledoc false
  use Mix.Task

  alias Algora.Admin
  alias Algora.Github

  require Logger

  @input_dir "dev/community/raw"
  @output_dir "dev/community"

  def run(_) do
    Application.ensure_all_started(:algora)

    # Create output directory if it doesn't exist
    output_path = Path.join(:code.priv_dir(:algora), @output_dir)
    File.mkdir_p!(output_path)

    # Process all JSON files in the input directory
    :algora
    |> :code.priv_dir()
    |> Path.join(@input_dir)
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".json"))
    |> Enum.each(&process_file/1)
  end

  defp process_file(filename) do
    input_path = Path.join([:code.priv_dir(:algora), @input_dir, filename])
    output_path = Path.join([:code.priv_dir(:algora), @output_dir, filename])

    Logger.info("Processing #{filename}")

    {:ok, content} = File.read(input_path)
    {:ok, users} = Jason.decode(content)

    updated_users =
      users
      |> Task.async_stream(
        fn user ->
          id = user["github_id"]

          case Github.get_user(Admin.token!(), id) do
            {:ok, user} ->
              user
              |> Map.put("github_handle", user["login"])
              |> maybe_update("bio", user["bio"])
              |> maybe_update("location", user["location"])
              |> maybe_update("company", user["company"])
              |> maybe_update("name", user["name"])

            {:error, reason} ->
              Logger.warning("Failed to fetch user #{id}: #{inspect(reason)}")
              user
          end
        end,
        timeout: 10_000,
        max_concurrency: 5
      )
      |> Enum.map(fn {:ok, user} -> user end)

    {:ok, json} = Jason.encode(updated_users, pretty: true)
    :ok = File.write(output_path, json)

    Logger.info("Successfully updated #{length(updated_users)} users in #{filename}")
  end

  defp maybe_update(map, key, value) do
    if non_empty?(value), do: Map.put(map, key, value), else: map
  end

  defp non_empty?(nil), do: false
  defp non_empty?(value) when is_binary(value), do: String.trim(value) != ""
end
