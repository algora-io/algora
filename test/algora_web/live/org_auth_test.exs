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
    test_path = "/org/#{org.handle}#{path}"

    # Test unauthorized access
    assert {:error, {:redirect, %{to: to}}} = live(conn, test_path)
    assert to == ~p"/auth/login?return_to=#{test_path}"

    # # Test non-member access
    user = insert!(:user)
    conn_with_user = AlgoraWeb.UserAuth.put_current_user(conn, user)
    assert {:error, {:redirect, %{to: to}}} = live(conn_with_user, test_path)
    assert to == "/org/#{org.handle}"

    # # Test access for each role
    member = insert!(:member, user: user, org: org)

    for role <- Member.roles() do
      member |> change(role: role) |> Repo.update!()

      if role in allowed_roles do
        assert {:ok, _view, _html} = live(conn_with_user, test_path)
      else
        assert {:error, {:redirect, %{to: to}}} = live(conn_with_user, test_path)
        assert to == "/org/#{org.handle}"
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
end
