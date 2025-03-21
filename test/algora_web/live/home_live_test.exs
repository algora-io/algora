defmodule AlgoraWeb.HomeLiveTest do
  use AlgoraWeb.ConnCase, async: true

  alias AlgoraWeb.HomeLive

  describe "parse_github_url/1" do
    test "parses full GitHub URLs" do
      assert HomeLive.parse_github_url("https://github.com/owner/repo") == {:ok, {"owner", "repo"}}
      assert HomeLive.parse_github_url("http://github.com/owner/repo") == {:ok, {"owner", "repo"}}
      assert HomeLive.parse_github_url("github.com/owner/repo") == {:ok, {"owner", "repo"}}
    end

    test "parses owner/repo format" do
      assert HomeLive.parse_github_url("owner/repo") == {:ok, {"owner", "repo"}}
    end

    test "handles URLs with dashes and underscores" do
      assert HomeLive.parse_github_url("my-org/my_repo") == {:ok, {"my-org", "my_repo"}}
      assert HomeLive.parse_github_url("github.com/my-org/my_repo") == {:ok, {"my-org", "my_repo"}}
    end

    test "handles numeric characters" do
      assert HomeLive.parse_github_url("owner123/repo456") == {:ok, {"owner123", "repo456"}}
    end

    test "rejects invalid formats" do
      error_msg = "Must be a valid GitHub repository URL (e.g. github.com/owner/repo) or owner/repo format"

      assert HomeLive.parse_github_url("") == {:error, error_msg}
      assert HomeLive.parse_github_url("invalid") == {:error, error_msg}
      assert HomeLive.parse_github_url("owner") == {:error, error_msg}
      assert HomeLive.parse_github_url("owner/") == {:error, error_msg}
      assert HomeLive.parse_github_url("/repo") == {:error, error_msg}
    end

    test "handles whitespace" do
      assert HomeLive.parse_github_url("  owner/repo  ") == {:ok, {"owner", "repo"}}
      assert HomeLive.parse_github_url("  github.com/owner/repo  ") == {:ok, {"owner", "repo"}}
    end
  end
end
