defmodule Algora.MoneyUtils do
  @moduledoc false
  def fmt_precise(money), do: Money.to_string(money, no_fraction_if_integer: false)
  def fmt_precise!(money), do: Money.to_string!(money, no_fraction_if_integer: false)

  @spec split_evenly(Money.t(), non_neg_integer()) :: [Money.t()]
  def split_evenly(_money, 0), do: []

  def split_evenly(money, parts) do
    {dividend, _remainder} = Money.split(money, parts)
    [dividend | split_evenly(Money.sub!(money, dividend), parts - 1)]
  end

  @spec to_minor_units(Money.t()) :: integer()
  def to_minor_units(money) do
    {_, amount_int, _, _} = Money.to_integer_exp(money)
    amount_int
  end

  @spec to_stripe_currency(Money.t()) :: String.t()
  def to_stripe_currency(money) do
    money.currency |> to_string() |> String.downcase()
  end

  # TODO: Find a way to make this obsolete
  # Why does ecto return {currency, amount} instead of Money.t()?
  def ensure_money_field(struct, field) do
    case Map.get(struct, field) do
      {currency, amount} -> Map.put(struct, field, Money.new!(currency, amount, no_fraction_if_integer: true))
      _ -> struct
    end
  end
end
