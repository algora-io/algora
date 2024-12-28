defmodule Algora.Github.CommandTest do
  use ExUnit.Case, async: true
  alias Algora.Github.Command
  import Money.Sigil

  describe "parse/1 with bounty command" do
    test "parses simple bounty amount" do
      assert {:ok, %{bounty: [{:amount, ~M[1000]usd}]}} ==
               Command.parse("/bounty 1000")
    end

    test "parses bounty with EN thousand separators and decimal points" do
      assert {:ok, %{bounty: [{:amount, ~M[1000.5]usd}]}} ==
               Command.parse("/bounty 1,000.5")
    end

    test "parses bounty with EN thousand separators" do
      assert {:ok, %{bounty: [{:amount, ~M[1_000_000]usd}]}} ==
               Command.parse("/bounty 1,000,000")
    end

    test "parses bounty with EN decimal points" do
      assert {:ok, %{bounty: [{:amount, ~M[1000.50]usd}]}} ==
               Command.parse("/bounty 1000.50")
    end

    test "parses bounty with DE thousand separators and decimal points" do
      assert {:ok, %{bounty: [{:amount, ~M[1000.5]usd}]}} ==
               Command.parse("/bounty 1.000,5")
    end

    test "parses bounty with DE thousand separators" do
      assert {:ok, %{bounty: [{:amount, ~M[1_000_000]usd}]}} ==
               Command.parse("/bounty 1.000.000")
    end

    test "parses bounty with DE decimal points" do
      assert {:ok, %{bounty: [{:amount, ~M[1000.50]usd}]}} ==
               Command.parse("/bounty 1000,50")
    end

    test "parses bounty with dollar sign" do
      assert {:ok, %{bounty: [{:amount, ~M[50]usd}]}} ==
               Command.parse("/bounty $50")
    end
  end

  describe "parse/1 with tip command" do
    test "parses tip with amount first" do
      assert {:ok, %{tip: [{:amount, ~M[100]usd}, {:username, "user"}]}} ==
               Command.parse("/tip 100 @user")
    end

    test "parses tip with username first" do
      assert {:ok, %{tip: [{:username, "user"}, {:amount, ~M[100]usd}]}} ==
               Command.parse("/tip @user 100")
    end

    test "parses tip with only amount" do
      assert {:ok, %{tip: [{:amount, ~M[100]usd}]}} ==
               Command.parse("/tip 100")
    end

    test "parses tip with only username" do
      assert {:ok, %{tip: [{:username, "user"}]}} ==
               Command.parse("/tip @user")
    end
  end

  describe "parse/1 with claim command" do
    test "parses simple issue number" do
      assert {:ok, %{claim: [{:ticket_ref, [number: 123]}]}} ==
               Command.parse("/claim 123")
    end

    test "parses issue with hash" do
      assert {:ok, %{claim: [{:ticket_ref, [number: 123]}]}} ==
               Command.parse("/claim #123")
    end

    test "parses repo issue reference" do
      assert {:ok, %{claim: [{:ticket_ref, [repo: "repo", number: 123]}]}} ==
               Command.parse("/claim repo#123")
    end

    test "parses full repo path" do
      assert {:ok, %{claim: [{:ticket_ref, [owner: "owner", repo: "repo", number: 123]}]}} ==
               Command.parse("/claim owner/repo#123")
    end

    test "parses full GitHub URL for issues" do
      expected =
        {:ok,
         %{
           claim: [{:ticket_ref, [owner: "owner", repo: "repo", type: "issues", number: 123]}]
         }}

      assert expected == Command.parse("/claim github.com/owner/repo/issues/123")
      assert expected == Command.parse("/claim http://github.com/owner/repo/issues/123")
      assert expected == Command.parse("/claim https://github.com/owner/repo/issues/123")
    end

    test "parses full GitHub URL for pull requests" do
      assert {:ok,
              %{
                claim: [{:ticket_ref, [owner: "owner", repo: "repo", type: "pull", number: 123]}]
              }} ==
               Command.parse("/claim https://github.com/owner/repo/pull/123")
    end

    test "parses full GitHub URL for discussions" do
      assert {:ok,
              %{
                claim: [
                  {:ticket_ref, [owner: "owner", repo: "repo", type: "discussions", number: 123]}
                ]
              }} ==
               Command.parse("/claim https://github.com/owner/repo/discussions/123")
    end
  end

  describe "parse/1 with multiple commands" do
    test "parses multiple commands in sequence" do
      assert {:ok,
              %{
                bounty: [{:amount, Money.new!(100, :USD)}],
                tip: [{:amount, Money.new!(50, :USD)}, {:username, "user"}]
              }} == Command.parse("/bounty 100 /tip 50 @user")
    end

    test "handles text between commands" do
      assert {:ok,
              %{
                bounty: [{:amount, Money.new!(100, :USD)}],
                tip: [{:username, "user"}, {:amount, Money.new!(50, :USD)}]
              }} == Command.parse("Hello /bounty 100 world /tip @user 50")
    end
  end

  describe "parse/1 with invalid input" do
    test "returns empty list for invalid commands" do
      assert {:ok, %{}} == Command.parse("/invalid")
    end

    test "returns empty list for no commands" do
      assert {:ok, %{}} == Command.parse("just some text")
    end

    test "returns error for malformed amounts" do
      assert {:error, "Invalid amount:" <> _amount} = Command.parse("/bounty 1.000.00")
      assert {:error, "Invalid amount:" <> _amount} = Command.parse("/bounty 1,000,00")
    end

    test "returns error for mixed number formats" do
      assert {:error, "Invalid amount:" <> _amount} = Command.parse("/bounty 1,000.000,00")
      assert {:error, "Invalid amount:" <> _amount} = Command.parse("/bounty 1.000,000.00")
    end
  end
end
