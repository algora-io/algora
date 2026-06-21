defmodule AlgoraWeb.User.SettingsLiveTest do
  use AlgoraWeb.ConnCase

  import Algora.Factory
  import Phoenix.LiveViewTest

  describe "timezone selector" do
    test "filters timezone options from a search input", %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> AlgoraWeb.UserAuth.put_current_user(user)

      {:ok, view, html} = live(conn, ~p"/user/settings")

      assert html =~ "Search Timezone"
      assert html =~ "America/Los_Angeles"

      html =
        render_change(view, :validate, %{
          "timezone_query" => "Johannesburg",
          "user" => %{
            "handle" => user.handle,
            "display_name" => user.display_name,
            "bio" => user.bio,
            "website_url" => user.website_url,
            "location" => user.location,
            "timezone" => user.timezone
          }
        })

      assert html =~ "Africa/Johannesburg"
      assert html =~ "America/Los_Angeles"
      refute html =~ "Asia/Tokyo"
    end
  end
end
