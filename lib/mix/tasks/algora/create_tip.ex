defmodule Mix.Tasks.Algora.CreateTip do
  @shortdoc "Creates a mock bounty"

  @moduledoc false
  use Mix.Task

  import Algora.Mocks.GithubMock

  def run(args) do
    Application.ensure_all_started(:algora)
    Application.ensure_all_started(:mox)
    Mox.defmock(Algora.GithubMock, for: Algora.Github.Behaviour)
    Application.put_env(:algora, :github_client, Algora.GithubMock)
    setup_get_issue()
    setup_get_repository()

    opts = parse_opts(args)
    from_user = Algora.Accounts.get_user_by_handle(opts[:from])
    to_user = Algora.Accounts.get_user_by_handle(opts[:to])
    amount = Money.new(opts[:amount], :USD)

    %{
      creator: from_user,
      owner: from_user,
      recipient: to_user,
      amount: amount
    }
    |> Algora.Bounties.create_tip()
    |> case do
      {:ok, _bounty} ->
        IO.puts("Tip created")

      {:error, :already_exists} ->
        IO.puts("Tip already created")
    end
  end

  defp parse_opts(args) do
    {opts, _, _} =
      OptionParser.parse(
        args,
        strict: [from: :string, to: :string, amount: :string]
      )

    opts
  end
end
