defmodule Algora.AccountsTest do
  use Algora.DataCase

  describe "accounts" do
    test "register github user" do
      email = "githubuser@example.com"

      info = %{
        "id" => "1234",
        "login" => "githubuser",
        "name" => "Github User"
      }

      {:ok, user} = Algora.Accounts.register_github_user(email, info, [email], "token123")
      {:ok, user_again} = Algora.Accounts.register_github_user(email, info, [email], "token123")

      assert_activity_names([:identity_created])
      assert_activity_names_for_user(user.id, [:identity_created])
      assert_activity_names_for_user(user_again.id, [:identity_created])
    end
  end
end
