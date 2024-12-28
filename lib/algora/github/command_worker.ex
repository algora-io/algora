defmodule Algora.Github.CommandWorker do
  use Oban.Worker, queue: :command_workers
  require Logger
  alias Algora.Bounties
  alias Algora.Workspace
  alias Algora.Github

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"event" => event, "command" => command} = _args}) do
    command =
      command
      |> Base.decode64!()
      |> :erlang.binary_to_term()

    run_command(command, event)
  end

  defp run_command({:bounty, args}, event) do
    # TODO: use user's own token if available
    token = Github.TokenPool.get_token()

    with {:ok, amount} <- Keyword.fetch(args, :amount),
         {:ok, user} <- Workspace.ensure_user(token, extract_actor(event)),
         {:ok, _bounty} <-
           Bounties.create_bounty(%{
             creator: user,
             owner: user,
             amount: amount,
             ticket_ref: extract_ticket_ref(event)
           }) do
      :ok
    else
      {:error, _reason} = error ->
        Logger.error("Failed to create bounty: #{inspect(error)}")
        error
    end
  end

  defp extract_actor(%{"actor" => %{"login" => login}}), do: login

  defp extract_ticket_ref(%{
         "repo" => %{"name" => repo_full_name},
         "payload" => %{"issue" => %{"number" => number}}
       }) do
    [repo_owner, repo_name] = String.split(repo_full_name, "/")
    %{owner: repo_owner, repo: repo_name, number: number}
  end
end
