defmodule AlgoraWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use AlgoraWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use AlgoraWeb, :verified_routes

      import AlgoraWeb.ConnCase
      import Phoenix.ConnTest
      import Plug.Conn
      # The default endpoint for testing
      @endpoint AlgoraWeb.Endpoint

      # Import conveniences for testing with connections
    end
  end

  setup tags do
    Algora.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def assert_activity_names(names) do
    assert Algora.Activities.all()
           |> Enum.reverse()
           |> Enum.map(&Map.get(&1, :type)) == names
  end

  def assert_activity_names(target, names) do
    assert target
           |> Algora.Activities.all()
           |> Enum.reverse()
           |> Enum.map(&Map.get(&1, :type)) == names
  end

  def assert_activity_names_for_user(user_id, names) do
    assert user_id
           |> Algora.Activities.all_for_user()
           |> Enum.reverse()
           |> Enum.map(&Map.get(&1, :type)) == names
  end
end
