defmodule Algora.UtilTest do
  use ExUnit.Case, async: true

  alias Algora.Util

  describe "format_pct/1" do
    test "formats decimal percentages correctly" do
      assert Util.format_pct(Decimal.new("1")) == "100%"
      assert Util.format_pct(Decimal.new("0.1")) == "10%"
      assert Util.format_pct(Decimal.new("0.156")) == "15.6%"
      assert Util.format_pct(Decimal.new("0.1567")) == "15.67%"
      assert Util.format_pct(Decimal.new("0.15678")) == "15.678%"
      assert Util.format_pct(Decimal.new("0")) == "0%"
    end

    test "trims trailing zeros" do
      assert Util.format_pct(Decimal.new("0.1500")) == "15%"
      assert Util.format_pct(Decimal.new("0.1050")) == "10.5%"
    end
  end

  describe "parse_github_url/1" do
    test "parses full GitHub URLs" do
      assert Util.parse_github_url("https://github.com/owner/repo") == {:ok, {"owner", "repo"}}
      assert Util.parse_github_url("http://github.com/owner/repo") == {:ok, {"owner", "repo"}}
      assert Util.parse_github_url("github.com/owner/repo") == {:ok, {"owner", "repo"}}
    end

    test "parses owner/repo format" do
      assert Util.parse_github_url("owner/repo") == {:ok, {"owner", "repo"}}
    end

    test "handles URLs with dashes and underscores" do
      assert Util.parse_github_url("my-org/my_repo") == {:ok, {"my-org", "my_repo"}}
      assert Util.parse_github_url("github.com/my-org/my_repo") == {:ok, {"my-org", "my_repo"}}
    end

    test "handles numeric characters" do
      assert Util.parse_github_url("owner123/repo456") == {:ok, {"owner123", "repo456"}}
    end

    test "rejects invalid formats" do
      error_msg = "Must be a valid GitHub repository URL (e.g. github.com/owner/repo) or owner/repo format"

      assert Util.parse_github_url("") == {:error, error_msg}
      assert Util.parse_github_url("invalid") == {:error, error_msg}
      assert Util.parse_github_url("owner") == {:error, error_msg}
      assert Util.parse_github_url("owner/") == {:error, error_msg}
      assert Util.parse_github_url("/repo") == {:error, error_msg}
    end

    test "handles whitespace" do
      assert Util.parse_github_url("  owner/repo  ") == {:ok, {"owner", "repo"}}
      assert Util.parse_github_url("  github.com/owner/repo  ") == {:ok, {"owner", "repo"}}
    end
  end

  describe "to_date!/1" do
    test "handles nil" do
      assert Util.to_date!(nil) == nil
    end

    test "converts ISO8601 with no microseconds" do
      datetime = Util.to_date!("2024-03-14T12:00:00Z")
      assert datetime.microsecond == {0, 6}
      assert datetime.year == 2024
      assert datetime.month == 3
      assert datetime.day == 14
      assert datetime.hour == 12
    end

    test "converts ISO8601 with partial microseconds" do
      datetime = Util.to_date!("2024-03-14T12:00:00.123Z")
      assert datetime.microsecond == {123_000, 6}
    end

    test "converts ISO8601 with full microseconds" do
      datetime = Util.to_date!("2024-03-14T12:00:00.123456Z")
      assert datetime.microsecond == {123_456, 6}
    end

    test "converts ISO8601 with excess precision" do
      datetime = Util.to_date!("2024-03-14T12:00:00.123456789Z")
      assert datetime.microsecond == {123_456, 6}
    end

    test "handles invalid format" do
      assert {:error, _reason} = Util.to_date!("invalid")
    end
  end
end
