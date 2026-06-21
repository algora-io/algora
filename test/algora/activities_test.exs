defmodule Algora.ActivitiesTest do
  use ExUnit.Case, async: true

  alias Algora.Activities
  alias Algora.Bounties.Bounty

  describe "schema_from_table/1" do
    test "does not create atoms for unknown table names" do
      table = "unknown_#{System.unique_integer([:positive])}_activities"

      refute existing_atom?(table)

      assert_raise KeyError, fn ->
        Activities.schema_from_table(table)
      end

      refute existing_atom?(table)
    end

    test "returns schemas for known table names" do
      assert Activities.schema_from_table("bounty_activities") == Bounty
    end
  end

  defp existing_atom?(value) do
    String.to_existing_atom(value)
    true
  rescue
    ArgumentError -> false
  end
end
