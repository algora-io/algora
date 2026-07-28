defmodule AlgoraWeb.Org.JobsLiveTest do
  use AlgoraWeb.ConnCase

  import Algora.Factory
  import Phoenix.LiveViewTest

  alias Algora.Jobs
  alias AlgoraWeb.UserAuth

  setup %{conn: conn} do
    {:ok, conn: Phoenix.ConnTest.init_test_session(conn, %{})}
  end

  test "lets a user withdraw an existing job application", %{conn: conn} do
    user = insert!(:user)
    org = insert!(:organization)
    job = insert!(:job_posting, user: org)

    assert {:ok, _application} = Jobs.create_application(job.id, user)

    {:ok, view, html} =
      conn
      |> UserAuth.put_current_user(user)
      |> live("/#{org.handle}/jobs")

    assert html =~ "Withdraw"
    assert has_element?(view, "button[phx-click=withdraw_application]", "Withdraw")
    refute has_element?(view, "button[phx-click=apply_job]", "I'm interested")

    view
    |> element("button[phx-click=withdraw_application]")
    |> render_click()

    assert has_element?(view, "button[phx-click=apply_job]", "I'm interested")
    refute has_element?(view, "button[phx-click=withdraw_application]", "Withdraw")
    assert {:error, :not_found} = Jobs.withdraw_application(job.id, user)
  end
end
