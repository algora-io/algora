defmodule Algora.Admin do
  alias Algora.Accounts
  alias Algora.Work

  def token!() do
    with [user] <- Accounts.list_users(limit: 1),
         {:ok, token} <- Accounts.get_access_token(user) do
      token
    end
  end

  def run!() do
    with {:ok, repo} <- Work.get_repository(:github, token!(), "algora-io", "tv") do
      IO.inspect(repo)
    end
  end
end
