defmodule Algora.AccountsTest do
  use Algora.DataCase

  alias Algora.Accounts

  describe "accounts" do
    test "register github user" do
      email = "githubuser@example.com"

      info = %{
        "id" => "1234",
        "login" => "githubuser",
        "name" => "Github User"
      }

      {:ok, user} = Accounts.register_github_user(email, info, [email], "token123")
      {:ok, user_again} = Accounts.register_github_user(email, info, [email], "token123")

      assert_activity_names([:identity_created])
      assert_activity_names_for_user(user.id, [:identity_created])
      assert_activity_names_for_user(user_again.id, [:identity_created])
    end

    test "query" do
      user_1 = insert(:user)
      user_2 = insert(:user, tech_stack: ["rust", "c++"])
      org_1 = insert(:organization, seeded: false)

      assert user_1.id |> Accounts.fetch_developer() |> elem(1) |> Map.get(:id) == user_1.id
      assert [sort_by_tech_stack: ["rust"]] |> Accounts.fetch_developer_by() |> elem(1) |> Map.get(:id) == user_2.id

      assert [] |> Accounts.list_developers() |> length() == 2
      assert [] |> Accounts.list_orgs() |> length() == 1

      assert_activity_names_for_user(user_1.id, [])
      assert_activity_names_for_user(org_1.id, [])
    end
  end
end
