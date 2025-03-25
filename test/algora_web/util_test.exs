defmodule AlgoraWeb.UtilTest do
  use AlgoraWeb.ConnCase

  alias AlgoraWeb.Util

  describe "build_safe_redirect/1" do
    test "returns root path for nil or empty URL" do
      assert Util.build_safe_redirect(nil) == [to: ~p"/"]
      assert Util.build_safe_redirect("") == [to: ~p"/"]
    end

    test "returns local path for relative URLs" do
      assert Util.build_safe_redirect("/dashboard") == [to: "/dashboard"]
      assert Util.build_safe_redirect("/settings/profile") == [to: "/settings/profile"]
    end

    test "returns local path for URLs with matching app host" do
      assert Util.build_safe_redirect("#{AlgoraWeb.Endpoint.url()}/dashboard") == [to: "/dashboard"]
    end

    test "allows external URLs for trusted domains" do
      # Test algora.io subdomain
      assert Util.build_safe_redirect("https://blog.algora.io/post") ==
               [external: "https://blog.algora.io/post"]

      # Test algora.tv domain
      assert Util.build_safe_redirect("https://watch.algora.tv/video") ==
               [external: "https://watch.algora.tv/video"]

      # Test github.com domain
      assert Util.build_safe_redirect("https://github.com/algora") ==
               [external: "https://github.com/algora"]

      # Test stripe.com domain
      assert Util.build_safe_redirect("https://checkout.stripe.com/c/pay/cs_test_b1t") ==
               [external: "https://checkout.stripe.com/c/pay/cs_test_b1t"]
    end

    test "redirects to root for untrusted domains" do
      assert Util.build_safe_redirect("https://malicious-site.com") == [to: ~p"/"]
      assert Util.build_safe_redirect("https://fake-algora.com") == [to: ~p"/"]
      assert Util.build_safe_redirect("https://stripe.fake.com") == [to: ~p"/"]
    end
  end
end
