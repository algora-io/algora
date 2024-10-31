defmodule Algora.GitHub.WebhookTest do
  use ExUnit.Case, async: true
  alias Algora.Github.Webhook

  describe "signature verification" do
    test "validates payload signature correctly" do
      signature = "sha256=757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17"
      secret = "It's a Secret to Everybody"
      payload = "Hello, World!"

      assert {:ok, _} = Webhook.verify_signature(signature, payload, secret)
    end

    test "returns error if signatures don't match" do
      signature = "sha256=757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17"
      secret = "It's a Secret"
      payload = "Hello, World!"

      assert {:error, :signature_mismatch} = Webhook.verify_signature(signature, payload, secret)
    end
  end
end
