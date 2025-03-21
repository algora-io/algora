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
end
