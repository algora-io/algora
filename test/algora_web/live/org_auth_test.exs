defmodule AlgoraWeb.Org.SettingsLiveTest do
  use AlgoraWeb.ConnCase, async: true

  import Algora.Factory
  import Ecto.Changeset
  import Phoenix.LiveViewTest

  alias Algora.Organizations.Member
  alias Algora.Repo

  setup %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, %{})

    %{
      conn: conn,
      org: insert!(:organization)
    }
  end

  # Helper function to test auth requirements for org routes
  defp assert_org_route_auth(conn, org, path, allowed_roles) do
    test_path = "/#{org.handle}#{path}"

    # Test unauthorized access
    assert {:error, {:redirect, %{to: to}}} = live(conn, test_path)
    assert to == ~p"/auth/login?return_to=#{test_path}"

    # # Test non-member access
    user = insert!(:user)
    conn_with_user = AlgoraWeb.UserAuth.put_current_user(conn, user)
    assert {:error, {:redirect, %{to: to}}} = live(conn_with_user, test_path)
    assert to == "/#{org.handle}"

    # # Test access for each role
    member = insert!(:member, user: user, org: org)

    for role <- Member.roles() do
      member |> change(role: role) |> Repo.update!()

      if role in allowed_roles do
        assert {:ok, _view, _html} = live(conn_with_user, test_path)
      else
        assert {:error, {:redirect, %{to: to}}} = live(conn_with_user, test_path)
        assert to == "/#{org.handle}"
      end
    end
  end

  describe "protected org routes" do
    for {path, roles} <- %{
          "/settings" => [:admin],
          "/transactions" => [:admin]
        } do
      test "#{path} page", %{conn: conn, org: org} do
        assert_org_route_auth(conn, org, unquote(path), unquote(Macro.escape(roles)))
      end
    end
  end

  describe "get_user_role/2" do
    test "returns :none for nil user", %{org: org} do
      assert :none = AlgoraWeb.OrgAuth.get_user_role(nil, org)
    end

    test "returns :admin for system admin user", %{org: org} do
      user = insert!(:user, is_admin: true)
      assert :admin = AlgoraWeb.OrgAuth.get_user_role(user, org)
    end

    test "returns :admin when user is org owner", %{org: org} do
      user = insert!(:user)
      # Set org.id to match user.id
      org = %{org | id: user.id}
      assert :admin = AlgoraWeb.OrgAuth.get_user_role(user, org)
    end

    test "returns member role for org member", %{org: org} do
      user = insert!(:user)
      insert!(:member, user: user, org: org, role: :mod)
      assert :mod = AlgoraWeb.OrgAuth.get_user_role(user, org)
    end

    test "returns :none for non-member user", %{org: org} do
      user = insert!(:user)
      assert :none = AlgoraWeb.OrgAuth.get_user_role(user, org)
    end
  end
end
