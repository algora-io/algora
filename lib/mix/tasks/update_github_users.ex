defmodule Mix.Tasks.UpdateGithubUsers do
  use Mix.Task
  require Logger
  alias Algora.Admin
  alias Algora.Github

  @shortdoc "Updates user data from GitHub"

  @input_file "dev/swift_experts_raw.json"
  @output_file "dev/swift_experts.json"

  def run(_) do
    Application.ensure_all_started(:algora)

    {:ok, content} = File.read(Path.join(:code.priv_dir(:algora), @input_file))
    {:ok, experts} = Jason.decode(content)

    updated_experts =
      experts
      |> Task.async_stream(
        fn expert ->
          handle = expert["github_handle"]

          case Github.get_user_by_username(Admin.token!(), handle) do
            {:ok, user} ->
              expert
              |> maybe_update("bio", user["bio"])
              |> maybe_update("location", user["location"])
              |> maybe_update("company", user["company"])
              |> maybe_update("name", user["name"])

            {:error, reason} ->
              Logger.warning("Failed to fetch user #{handle}: #{inspect(reason)}")
              expert
          end
        end,
        timeout: 10_000,
        max_concurrency: 5
      )
      |> Enum.map(fn {:ok, expert} -> expert end)

    {:ok, json} = Jason.encode(updated_experts, pretty: true)
    :ok = File.write(Path.join(:code.priv_dir(:algora), @output_file), json)

    Logger.info("Successfully updated #{length(updated_experts)} experts")
  end

  defp maybe_update(map, key, value) do
    if non_empty?(value), do: Map.put(map, key, value), else: map
  end

  defp non_empty?(nil), do: false
  defp non_empty?(value) when is_binary(value), do: String.trim(value) != ""
end
