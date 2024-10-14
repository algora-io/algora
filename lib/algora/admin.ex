defmodule Algora.Admin do
  alias Algora.Accounts

  def token!() do
    with [user] <- Accounts.list_users(limit: 1),
         {:ok, token} <- Accounts.get_access_token(user) do
      token
    end
  end
end
