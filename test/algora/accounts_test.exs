defmodule Algora.AccountsTest do
  use Algora.DataCase

  alias Algora.Accounts
  alias Algora.Accounts.Identity
  alias Algora.Accounts.User
  alias Algora.Organizations
  alias Algora.Repo
  alias Algora.Workspace.Repository

  describe "register_github_user/5" do
    setup do
      # Sample GitHub info that would come from OAuth
      github_info = %{
        "id" => "12345",
        "login" => "testuser",
        "name" => "Test User",
        "avatar_url" => "https://example.com/avatar.jpg",
        "bio" => "Test bio"
      }

      emails = [
        %{"email" => "test@example.com", "primary" => true, "verified" => true},
        %{"email" => "other@example.com", "primary" => false, "verified" => true}
      ]

      token = "github_oauth_token_123"
      primary_email = "test@example.com"

      {:ok,
       %{
         github_info: github_info,
         emails: emails,
         token: token,
         primary_email: primary_email
       }}
    end

    test "creates new user when no matching accounts exist", %{
      github_info: github_info,
      emails: emails,
      token: token,
      primary_email: primary_email
    } do
      {:ok, user} = Accounts.register_github_user(nil, primary_email, github_info, emails, token)

      assert user.provider == "github"
      assert user.provider_id == "12345"
      assert user.email == primary_email
      assert user.provider_login == "testuser"

      identity = Repo.get_by(Identity, user_id: user.id)
      assert identity.provider == "github"
      assert identity.provider_token == token
    end

    test "updates existing user when matching by GitHub ID", %{
      github_info: github_info,
      emails: emails,
      token: token,
      primary_email: primary_email
    } do
      {:ok, existing_user} = Accounts.register_github_user(nil, "old@example.com", github_info, emails, "old_token")

      identity = Repo.get_by(Identity, user_id: existing_user.id)
      assert identity.provider_token == "old_token"

      {:ok, updated_user} = Accounts.register_github_user(existing_user, primary_email, github_info, emails, token)

      assert updated_user.id == existing_user.id
      assert updated_user.email == "old@example.com"
      assert updated_user.provider_login == "testuser"

      assert Repo.get(Identity, identity.id) == nil
      assert Repo.get_by(Identity, user_id: updated_user.id).provider_token == token
    end

    test "links accounts when current user email matches GitHub email", %{
      github_info: github_info,
      emails: emails,
      token: token,
      primary_email: primary_email
    } do
      # Create existing user with matching email but no GitHub connection
      existing_user = insert!(:user, email: primary_email, display_name: "Existing User")

      {:ok, updated_user} = Accounts.register_github_user(existing_user, primary_email, github_info, emails, token)

      assert updated_user.id == existing_user.id
      assert updated_user.provider == "github"
      assert updated_user.provider_id == "12345"

      identity = Repo.get_by(Identity, user_id: updated_user.id)
      assert identity.provider == "github"
      assert identity.provider_token == token
    end

    test "migrates data when merging duplicate accounts", %{
      github_info: github_info,
      emails: emails,
      token: token,
      primary_email: primary_email
    } do
      # Create a GitHub-connected user
      {:ok, github_user} = Accounts.register_github_user(nil, "other@example.com", github_info, emails, "old_token")

      # Create another user with matching email
      email_user = insert!(:user, email: primary_email, display_name: "Email User")

      # Create some associated data for the GitHub user
      repository = insert!(:repository, user: github_user, name: "test-repo")

      {:ok, merged_user} = Accounts.register_github_user(email_user, primary_email, github_info, emails, token)

      # Verify the accounts were merged
      assert merged_user.id == email_user.id

      # Verify associated data was migrated
      updated_repository = Repo.get(Repository, repository.id)
      assert updated_repository.user_id == merged_user.id

      # Verify the old user's GitHub connection was removed
      old_user = Repo.get(User, github_user.id)
      assert is_nil(old_user.provider)
      assert is_nil(old_user.provider_id)
    end

    test "is idempotent and creates activities", %{
      github_info: github_info,
      emails: emails,
      token: token,
      primary_email: primary_email
    } do
      {:ok, user} = Accounts.register_github_user(nil, primary_email, github_info, emails, token)
      {:ok, user_again} = Accounts.register_github_user(user, primary_email, github_info, emails, token)

      assert user.id == user_again.id
      assert_activity_names([:identity_created, :identity_created])
      assert_activity_names_for_user(user.id, [:identity_created])
      assert_activity_names_for_user(user_again.id, [:identity_created])
    end
  end

  describe "accounts" do
    test "query" do
      user_1 = insert(:user)
      user_2 = insert(:user, tech_stack: ["rust", "c++"])

      org_1 = insert(:organization, featured: true)
      _tx = insert(:transaction, user: org_1, net_amount: Money.new(1000, :USD), type: :debit, status: :succeeded)

      assert user_1.id |> Accounts.fetch_developer() |> elem(1) |> Map.get(:id) == user_1.id
      assert [sort_by_tech_stack: ["rust"]] |> Accounts.fetch_developer_by() |> elem(1) |> Map.get(:id) == user_2.id

      assert [] |> Accounts.list_developers() |> length() == 2
      assert [] |> Organizations.list_orgs() |> length() == 1

      assert_activity_names_for_user(user_1.id, [])
      assert_activity_names_for_user(org_1.id, [])
    end
  end

  describe "set_context/2" do
    test "can set context to personal" do
      user = insert(:user, last_context: nil)

      assert {:ok, user} = Accounts.set_context(user, "personal")
      assert Accounts.last_context(user) == "personal"
    end

    test "can set context to member org" do
      user = insert(:user, last_context: nil)
      org = insert(:organization)
      insert(:member, user: user, org: org)

      assert {:ok, user} = Accounts.set_context(user, org.handle)
      assert Accounts.last_context(user) == org.handle
    end

    test "cannot set context to non-member org" do
      user = insert(:user, last_context: nil)
      org = insert(:organization)

      assert {:error, :unauthorized} = Accounts.set_context(user, org.handle)
      assert Accounts.last_context(user) == "personal"
    end
  end
end
