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
end
