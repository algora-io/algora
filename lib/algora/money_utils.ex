defmodule Algora.MoneyUtils do
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
end
