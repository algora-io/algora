defmodule AlgoraWeb.UserAuthTest do
  use AlgoraWeb.ConnCase

  alias AlgoraWeb.UserAuth

  describe "verify_login_code/2" do
    test "successfully verifies simple email token" do
      email = "test@example.com"
      code = UserAuth.generate_login_code(email)

      assert {:ok, result} = UserAuth.verify_login_code(code, email)
      assert result.email == email
      assert result.token == code
    end

    test "rejects invalid email" do
      email = "test@example.com"
      code = UserAuth.generate_login_code(email)

      assert {:error, :invalid_email} = UserAuth.verify_login_code(code, "wrong@example.com")
    end

    test "successfully verifies token with domain and tech stack" do
      email = "test@example.com"
      domain = "example.com"
      tech_stack = ["Elixir", "Phoenix"]
      code = UserAuth.generate_login_code(email, domain, tech_stack)

      assert {:ok, result} = UserAuth.verify_login_code(code, email)
      assert result.email == email
      assert result.domain == domain
      assert result.tech_stack == tech_stack
      assert result.token == code
    end

    test "handles empty domain correctly" do
      email = "test@example.com"
      tech_stack = ["Elixir"]
      code = UserAuth.generate_login_code(email, "", tech_stack)

      assert {:ok, result} = UserAuth.verify_login_code(code, email)
      assert result.email == email
      assert result.domain == nil
      assert result.tech_stack == tech_stack
    end

    test "handles empty tech stack correctly" do
      email = "test@example.com"
      domain = "example.com"
      code = UserAuth.generate_login_code(email, domain, [])

      assert {:ok, result} = UserAuth.verify_login_code(code, email)
      assert result.email == email
      assert result.domain == domain
      assert result.tech_stack == []
    end

    test "rejects tampered tokens" do
      code = "tampered.token.here"
      assert {:error, :invalid} = UserAuth.verify_login_code(code, "test@example.com")
    end

    test "rejects expired tokens" do
      email = "test@example.com"
      original_config = Application.get_env(:algora, :login_code)
      Application.put_env(:algora, :login_code, Keyword.put(original_config, :ttl, 1))

      code = UserAuth.generate_login_code(email)
      Process.sleep(1500)

      assert {:error, :expired} = UserAuth.verify_login_code(code, email)

      Application.put_env(:algora, :login_code, original_config)
    end

    test "handles nil input" do
      assert {:error, :missing} = UserAuth.verify_login_code(nil, "test@example.com")
    end

    test "handles empty string input" do
      assert {:error, :invalid} = UserAuth.verify_login_code("", "test@example.com")
    end
  end

  describe "verify_preview_code/2" do
    test "successfully verifies simple id token" do
      id = "123"
      code = UserAuth.sign_preview_code(id)

      assert {:ok, result} = UserAuth.verify_preview_code(code, id)
      assert result == id
    end

    test "rejects invalid id" do
      id = "123"
      code = UserAuth.sign_preview_code(id)

      assert {:error, :invalid_id} = UserAuth.verify_preview_code(code, "wrong")
    end

    test "rejects tampered tokens" do
      code = "tampered.token.here"
      assert {:error, :invalid} = UserAuth.verify_preview_code(code, "123")
    end

    test "rejects expired tokens" do
      id = "123"
      original_config = Application.get_env(:algora, :login_code)
      Application.put_env(:algora, :login_code, Keyword.put(original_config, :ttl, 1))

      code = UserAuth.sign_preview_code(id)
      Process.sleep(1500)

      assert {:error, :expired} = UserAuth.verify_preview_code(code, id)

      Application.put_env(:algora, :login_code, original_config)
    end

    test "handles nil input" do
      assert {:error, :missing} = UserAuth.verify_preview_code(nil, "123")
    end

    test "handles empty string input" do
      assert {:error, :invalid} = UserAuth.verify_preview_code("", "123")
    end
  end
end
