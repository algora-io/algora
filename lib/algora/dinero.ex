defmodule Algora.Dinero do
  def split(_money, 0), do: []

  def split(money, parts) do
    {dividend, _remainder} = Money.split(money, parts)
    [dividend | split(Money.sub!(money, dividend), parts - 1)]
  end

  def to_integer(money) do
    {_, amount_int, _, _} = Money.to_integer_exp(money)
    amount_int
  end
end
