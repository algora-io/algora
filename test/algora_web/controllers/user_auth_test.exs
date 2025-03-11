defmodule AlgoraWeb.UserAuthTest do
  use AlgoraWeb.ConnCase

  alias AlgoraWeb.UserAuth

  describe "verify_login_code/1" do
    test "successfully verifies simple email token" do
      email = "test@example.com"
      code = UserAuth.generate_login_code(email)

      assert {:ok, %{email: ^email, token: ^code}} = UserAuth.verify_login_code(code)
    end

    test "successfully verifies token with domain and tech stack" do
      email = "test@example.com"
      domain = "example.com"
      tech_stack = ["Elixir", "Phoenix"]
      code = UserAuth.generate_login_code(email, domain, tech_stack)

      assert {:ok, result} = UserAuth.verify_login_code(code)
      assert result.email == email
      assert result.domain == domain
      assert result.tech_stack == tech_stack
      assert result.token == code
    end

    test "handles empty domain correctly" do
      email = "test@example.com"
      tech_stack = ["Elixir"]
      code = UserAuth.generate_login_code(email, "", tech_stack)

      assert {:ok, result} = UserAuth.verify_login_code(code)
      assert result.email == email
      assert result.domain == nil
      assert result.tech_stack == tech_stack
    end

    test "handles empty tech stack correctly" do
      email = "test@example.com"
      domain = "example.com"
      code = UserAuth.generate_login_code(email, domain, [])

      assert {:ok, result} = UserAuth.verify_login_code(code)
      assert result.email == email
      assert result.domain == domain
      assert result.tech_stack == []
    end

    test "rejects tampered tokens" do
      code = "tampered.token.here"
      assert {:error, :invalid} = UserAuth.verify_login_code(code)
    end

    test "rejects expired tokens" do
      email = "test@example.com"
      original_config = Application.get_env(:algora, :login_code)
      Application.put_env(:algora, :login_code, Keyword.put(original_config, :ttl, 1))

      code = UserAuth.generate_login_code(email)
      Process.sleep(1500)

      assert {:error, :expired} = UserAuth.verify_login_code(code)

      Application.put_env(:algora, :login_code, original_config)
    end

    test "handles nil input" do
      assert {:error, :missing} = UserAuth.verify_login_code(nil)
    end

    test "handles empty string input" do
      assert {:error, :invalid} = UserAuth.verify_login_code("")
    end
  end
end
